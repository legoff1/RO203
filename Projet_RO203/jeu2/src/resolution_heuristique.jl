include("generation.jl")

#Fonction pour faire la matrice des poids
function matrice_poids(matrice::Matrix)
    nrows, ncols = size(matrice)
    matrice_p = zeros(Int64, nrows,ncols)
    for i in 1:nrows
        for j in 1:ncols
            if matrice[i, j] == 0
                matrice_p[i,j] = 0
            else  
                val_possibles = vcat(matrice[i,:],matrice[:,j])
                poids = count(x -> x == matrice[i,j], val_possibles) - 2
                poids = convert(Int, poids)
                matrice_p[i,j] = poids
            end
        end 
    end
    return matrice_p
end 

#Fonction pour faire la matrice des populations des voisins de meme poids
function matrice_voisins_poids(matrice::Matrix)
    nrows, ncols = size(matrice)
    matrice_v_p = zeros(Int64, nrows,ncols)
    max_value = maximum(matrice)
    for i in 1:nrows
        for j in 1:ncols
            if matrice[i, j] == max_value
                voisins = []
                if i > 1
                push!(voisins, matrice[i-1,j])  # Voisin au-dessus
                end
                if i < nrows
                push!(voisins, matrice[i+1,j])  # Voisin en-dessous
                end
                if j > 1
                push!(voisins, matrice[i,j-1])  # Voisin à gauche
                end
                if j < ncols
                push!(voisins, matrice[i,j+1])  # Voisin à droite
                end
                compteur = count(x -> x == max_value, voisins)
                matrice_v_p[i,j] = compteur
            end
        end 
    end
    return matrice_v_p
end 

#Fonction pour cocher le plus rentable en verfiant que cela respecte les regles du jeu
function cocher_une_case(matrice::Matrix, matrice_p::Matrix, matrice_v_p::Matrix)
    nrows, ncols = size(matrice)
    max_value = maximum(matrice_p)
    candidates = []
    for i in 1:nrows
        for j in 1:ncols
            if matrice_p[i,j] == max_value
                voisins = matrice_v_p[i,j]
                push!(candidates, (i,j,voisins))
            end
        end
    end
    sort!(candidates, by = x -> x[3])

    for case in candidates
        buffer = matrice[case[1],case[2]]
        matrice[case[1],case[2]] = 0
        if check_zeros(matrice)
            if convex_dfs(matrice)
                return true, matrice
            end
        end
        matrice[case[1],case[2]] = buffer
    end

    return false, matrice
end

#Fonction principale qui coche des cases tant que le jeu n'est pas résolu
function heuristicSolve(matrice::Matrix)
    nrows, ncols = size(matrice)
    matrice_p = matrice_poids(matrice)
    isSolved = false
    while matrice_p != zeros(Int, nrows, ncols)
        matrice_v_p = matrice_voisins_poids(matrice_p)
        if !cocher_une_case(matrice, matrice_p, matrice_v_p)[1]
            return isSolved, matrice
        end
        matrice = cocher_une_case(matrice, matrice_p, matrice_v_p)[2]
        matrice_p = matrice_poids(matrice)
    end
    isSolved = true
    return isSolved, matrice
end
        



