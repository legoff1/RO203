function readInputFile(inputFile::String)

    # Open the input file
    datafile = open(inputFile)

    data = readlines(datafile)
    close(datafile)
    
    n = length(split(data[1], ","))
    t = Matrix{Int64}(undef, n, n)

    lineNb = 1

    # For each line of the input file
    for line in data

        lineSplit = split(line, ",")

        if size(lineSplit, 1) == n
            for colNb in 1:n

                if lineSplit[colNb] != " "
                    t[lineNb, colNb] = parse(Int64, lineSplit[colNb])
                else
                    t[lineNb, colNb] = 0
                end
            end
        end 
        
        lineNb += 1
    end

    return t

end

function displayGrid(t::Matrix{Int64})

    n = size(t, 1)
    
    # Display the upper border of the grid
    println(" ", "-"^(3*n-1)) 
    
    # For each cell (l, c)
    for l in 1:n
        print("|")
        for c in 1:n
            print(" ")
            
            if t[l, c] == 0
                print(" -")
            else
                
                print(t[l, c])
            end
            print(" ")
        end
        println("|")
    end
    println(" ", "-"^(3*n-1)) 

end

function saveInstance(t::Matrix{Int64}, outputFile::String)

    n = size(t, 1)

    # Open the output file
    writer = open(outputFile, "w")

    # For each cell (l, c) of the grid
    for l in 1:n
        for c in 1:n

            # Write its value
            if t[l, c] == 0
                print(writer, " ")
            else
                print(writer, t[l, c])
            end

            if c != n
                print(writer, ",")
            else
                println(writer, "")
            end
        end
    end

    close(writer)
    
end 

function writeSolution(fout::IOStream, t::Matrix{Int64})
    
    println(fout, "t = [")
    n = size(t, 1)
    
    for l in 1:n

        print(fout, "[ ")
        
        for c in 1:n
            print(fout, string(t[l, c]) * " ")
        end 

        endLine = "]"

        if l != n
            endLine *= ";"
        end

        println(fout, endLine)
    end

    println(fout, "]")
end 
