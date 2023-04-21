# Explaination:
# Soit y[i, j] une matrice de variables binaires de la même taille que la matrice d'entrée.

# Fonction objectif : Maximiser le nombre total de cellules non masquées dans la matrice.

# max ∑∑ y[i, j]
# i, j

# Contraintes :
# a. Unicité des valeurs : Pour chaque ligne et chaque colonne, nous ajoutons des contraintes pour garantir qu'aucune valeur ne se répète plus d'une fois parmi les cellules non masquées. Autrement dit, si une valeur apparaît dans une ligne ou une colonne, elle ne peut pas être répétée dans cette même ligne ou colonne parmi les cellules non masquées.

# Pour chaque i (ligne) et k (valeur) :
# ∑ (matrix[i, j] == k ? y[i, j] : 0) <= 1, pour tout j

# Pour chaque j (colonne) et k (valeur) :
# ∑ (matrix[i, j] == k ? y[i, j] : 0) <= 1, pour tout i

# b. Isolation : Nous ajoutons des contraintes pour garantir que les cellules masquées ne sont pas connectées entre elles. Pour ce faire, nous imposons des contraintes pour que chaque paire de cellules adjacentes horizontalement ou verticalement, au moins l'une des deux cellules est non masquée.

# Pour chaque i (ligne) et j (colonne) sauf la dernière ligne :
# y[i, j] + y[i+1, j] >= 1

# Pour chaque i (ligne) et j (colonne) sauf la dernière colonne :
# y[i, j] + y[i, j+1] >= 1

# c. Connectivity: pas possible de l'imprinter par LPI

using CPLEX
using JuMP
using MathOptInterface

include("resolution_heuristique.jl")
include("generation.jl")
include("io.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(matrix::Array{Int64, 2})

    m, n = size(matrix)
    
    display(matrix)

    # Create the model
    model = Model(CPLEX.Optimizer)

    # Decision variables
    @variable(model, y[1:m, 1:n], Bin)

    # Objective function
    @objective(model, Max, sum(y))

    # Constraints
    # y[i,j] == 0 if masked, otherwise y[i,j] == 1;

    # no.1 chaque nombre peut être visible seulement 1 fois au plus dans chaque column ou chaque rang
    for i in 1:m
        for k in 1:maximum(matrix)
            @constraint(model, sum((matrix[i, j] == k ? y[i, j] : 0) for j in 1:n) <= 1)
        end
    end

    for j in 1:n
        for k in 1:maximum(matrix)
            @constraint(model, sum((matrix[i, j] == k ? y[i, j] : 0) for i in 1:m) <= 1)
        end
    end

    # no.2 les cases masqués ne peuvent pas être adjacentes.
    for i in 1:m-1
        for j in 1:n
            @constraint(model, y[i, j] + y[i+1, j] >= 1)
        end
    end

    for i in 1:m
        for j in 1:n-1
            @constraint(model, y[i, j] + y[i, j+1] >= 1)
        end
    end

    # no.3 les cases non-masqués doit être convexe (solution compromis, 
    #      le performance déscend au fur et à mesure que le taille de matrice augmente.)
    
    # no.3.1 les seules cases qui sont pas dans les coins sont pas isolés
    for i in 2:m-1
        for j in 2:n-1
            @constraint(model, y[i-1, j] + y[i+1, j] + y[i,j-1] + y[i, j+1] >= 1)
        end
    end

    # no.3.2 les cases dans les bornes sont pas isolés
    for j in 2:n-1
        @constraint(model, y[1, j-1] + y[1, j+1] + y[2, j] >= 1)
        @constraint(model, y[m, j-1] + y[m, j+1] + y[m-1, j] >= 1)
    end

    for i in 2:m-1
        @constraint(model, y[i-1, 1] + y[i+1, 1] + y[i, 2] >= 1)
        @constraint(model, y[i-1, n] + y[i+1, n] + y[i, n-1] >= 1)
    end

    # no.3.3 assurer qu'il n'y a pas une diagonale travers la matrice;
    if  m < n
        for j in 2:n-1
            sum_r = 0
            sum_l = 0
            for i in 1:m
                if (j-i+1 >= 1) && (j+i-1 <= n) 
                    sum_r += y[i, j+i-1]
                    sum_l += y[i, j-i+1]
                end
            end
            @constraint(model, sum_r >= 1)
            @constraint(model, sum_l >= 1)
        end
    else
        for i in 2:m-1
            sum_u = 0
            sum_d = 0
            for j in 1:n
                if (i-j+1 >= 1) && (i+j-1 <= m) 
                    sum_u += y[i-j+1, j]
                    sum_d += y[i+j-1, j]
                end
            end
            @constraint(model, sum_u >= 1)
            @constraint(model, sum_d >= 1)
        end
    end

    
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(model)

    # Post-processing: Check connectivity
    function is_connected(solution::Array)
        return true
    end

    mask = JuMP.value.(y)


    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    # 3 - the mask matrix
    println("Before Return")
    display(convert.(Int64, round.(matrix .* mask)))
    return is_connected(mask), time() - start, convert.(Int64, round.(matrix .* mask))
    
end

"""
Heuristically solve an instance
"""


"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "../data/"
    resFolder = "../res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex","heuristique"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        matrice = readInputFile(dataFolder * file)

        # TODO
        println("In file resolution.jl, in method solveDataSet(), TODO: read value returned by readInputFile()")
        
        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    # Solve it and get the results
                    isOptimal, resolutionTime, solution = cplexSolve(matrice)
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fout,solution)
                    end

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    #while !isSolved && resolutionTime < 100
                        
                    # TODO 
                    #println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                    
                    # Solve it and get the results
                    isSolved, solution = heuristicSolve(matrice)
                    resolutionTime = time() - startingTime
                    

                    # Stop the chronometer
                    if isSolved
                        writeSolution(fout,solution)
                    end 

                        
                    #end

                    # Write the solution (if any)
                    """
                    if isSolved

                        # TODO
                        writeSolution(fout,solution)
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                    """
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end
