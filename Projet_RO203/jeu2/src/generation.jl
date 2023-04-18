using Random

include("io.jl")




# This file contains methods to generate a data set of instances (i.e., sudoku grids)
include("io.jl")

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""
function generateInstance(n::Int64, density::Float64)

    d = floor(Int, n*n*density)
    matrice = generer_matrice_sans_problemes(n)
    matrice_masque = replace_with_zeros(matrice,d)
    matrice = creer_problemes(matrice, matrice_masque)
    println("Voici une instance du jeu singles")
    println(matrice_masque)
    return matrice
    
end 

"""
Generate all the instances

Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()

    # For each grid size considered
    for size in [4, 5, 6, 10, 20]

        # For each grid density considered
        for density in [0.1 0.2 0.25]

            # Generate 10 instances
            for instance in 1:10

                fileName = "../data/instance_t" * string(size) * "_d" * string(density) * "_" * string(instance) * ".txt"

                if !isfile(fileName)
                    println("-- Generating file " * fileName)
                    saveInstance(generateInstance(size, density), fileName)
                end 
            end
        end
    end
end


#on fait une matrice qui n'a pas de problèmes
function generer_matrice_sans_problemes(n::Int64)
    matrice = zeros(Int, n, n)  # initialisation de la matrice avec des zéros

    for i in 1:n
        for j in 1:n
            matrice[i, j] = mod(j + i - 2, n) + 1  # calcul de la valeur pour chaque élément de la matrice
        end
    end
    #on permutte des lignes aléatoirement
    lignes_permutees = randperm(n)
    matrice = matrice[lignes_permutees, :]
    #on permutte des colonnes aléatoirement
    colonnes_permutees = randperm(n)
    matrice = matrice[:, colonnes_permutees]

    return matrice
end 




# Ceci ets une fonction qui verifie que les cases non nulles sont connexes 
function convex_dfs(matrix::Matrix)
    nrows, ncols = size(matrix)
    # Trouver la première case non nulle dans la matrice
    start_row = 0
    start_col = 0
    for i in 1:nrows
        for j in 1:ncols
            if matrix[i,j] != 0
                start_row = i
                start_col = j
                break
            end
        end
        if start_row != 0
            break
        end
    end
    # Si la matrice ne contient pas de cases non nulles, elle est convexe
    if start_row == 0
        return true
    end
    # Visiter toutes les cases non nulles en utilisant DFS
    visited = falses(nrows, ncols)
    stack = [(start_row, start_col)]
    while !isempty(stack)
        row, col = pop!(stack)
        visited[row, col] = true
        # Ajouter les cases voisines non visitées à la pile
        if row > 1 && matrix[row-1, col] != 0 && !visited[row-1, col]
            push!(stack, (row-1, col))
        end
        if row < nrows && matrix[row+1, col] != 0 && !visited[row+1, col]
            push!(stack, (row+1, col))
        end
        if col > 1 && matrix[row, col-1] != 0 && !visited[row, col-1]
            push!(stack, (row, col-1))
        end
        if col < ncols && matrix[row, col+1] != 0 && !visited[row, col+1]
            push!(stack, (row, col+1))
        end
    end
    # Vérifier que toutes les cases non nulles ont été visitées
    for i in 1:nrows
        for j in 1:ncols
            if matrix[i,j] != 0 && !visited[i,j]
                return false
            end
        end
    end
    return true
end

# ceci est une fonction qui verifie que deux zeros ne sont pas a coté dans une matrice
function check_zeros(matrice::Matrix)
    nrows, ncols = size(matrice)
    for i in 1:nrows
        for j in 1:ncols
            if matrice[i, j] == 0
                # Vérifier si les cases voisines contiennent des zéros
                if i > 1 && matrice[i-1, j] == 0
                    return false
                end
                if i < nrows && matrice[i+1, j] == 0
                    return false
                end
                if j > 1 && matrice[i, j-1] == 0
                    return false
                end
                if j < ncols && matrice[i, j+1] == 0
                    return false
                end
            end
        end
    end
    return true
end


function replace_with_zeros(matrice::Matrix, d::Int)
    nrows, ncols = size(matrice)
    new_matrice = copy(matrice)
    count = 0
    while count < d
        i, j = rand(1:nrows), rand(1:ncols)
        if new_matrice[i,j] != 0
            # remplace l'élément par un zéro et vérifie la condition
            new_matrice[i,j] = 0
            if check_zeros(new_matrice)
                if convex_dfs(new_matrice)
                    count += 1
                else
                    # annule le remplacement
                    new_matrice[i,j] = matrice[i,j]
                end
            else
                # annule le remplacement
                new_matrice[i,j] = matrice[i,j]
            end
        end
    end
    return new_matrice
end

function creer_problemes(matrice::Matrix, matrice_masque::Matrix)
    nrows, ncols = size(matrice)
    for i in 1:nrows
        for j in 1:ncols
            if matrice_masque[i, j] == 0
                val_possibles = vcat(matrice_masque[i,:],matrice_masque[:,j])
                val_possibles = filter(x -> x != 0, val_possibles)
                valeur = rand(val_possibles)
                matrice[i,j] = valeur
            end
        end 
    end
    return matrice
end 



