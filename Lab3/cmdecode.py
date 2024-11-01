'''
Things to know:
to input a hardcoded(immediate) value: input as a 12 bit binary number
values not fitting this spec will be asssumed to be names for a memory address
if you type in an arbitrary string where a memeory adress is too be used, that string becuase a name for that address
registors do not have names, to reference a reg use a 4 bit binary number
spaces are the seperators between terms
CC should be written out as in assignment, except you must use an underscore for No_Carry
Upper/lowercase is ignored
Branch statement is Immediate branching. The value placed into the mem field is the line of code that will be executed. place a decimal number here
shift/rotate amounts are entered as decimal numbers between -2048 and 2047
one intruction per line
/ is a commment line
parity flag is true if there are an even number of ones in the result, so branch will execute on even parity
flags are not reset by non alu 

Sample code that does nothing but is syntaticaly correct:

nop
hlt
ld 0000 101010101010
ld 1111 mem0
str mem0 111100001111
str mem1 0011
bra 24 always
bra 98 parity
bra 1 even
bra 7 carry
bra 2 negative
bra 4 zero
bra 9 no_Carry
bra 3 positive
/look a comment
xor 0010 1001
xor 1101 111100001111
add 0010 1001
add 1101 111100001111
rot 0011 6
rot 0010 -4
shf 0011 6
shf 0010 -4
hlt
cmp 0010 1001
cmp 1101 111100001111
'''


def removeChar(input: str, char:str):#utility: removes the charater char from the string and returns it
    if input.find(char) == -1:
        return input
    else:
        inlist = input.rsplit(char)
        output = ""
        for segments in inlist:
            output = output + segments
        return output
    
def isBinary(input:str): #returns true if the string is only ones and zeros
    zerocount = input.count("0")
    onecount = input.count("1")
    return (zerocount + onecount) == len(input)

memNames = [] # A list to hold all the names people have given their memory addresses. The array index is actually the position of the item
def getaddress(name:str):
    if memNames.count(name) == 0:#new memory name
        memNames.append(name)
        print(name + " placed in address " + str(memNames.index(name)))
    binary = format(memNames.index(name),'b')
    charsNeeded = 12 - len(binary)
    for x in range(charsNeeded): #append 0s to make the adress length 12
        binary = "0" + binary
    return binary
    
def twosComplement(decimal:int):#returns a string of twos complement binary reprenstation
    if decimal > -1:
        binary = format(decimal,'b')
        charsNeeded = 12 - len(binary)
        for x in range(charsNeeded): #append 0s to make the adress length 12
            binary = "0" + binary
        return binary
    else:
        binary = format((decimal + 1)*-1,'b')
        charsNeeded = 12 - len(binary)
        for x in range(charsNeeded): #append 0s to make the adress length 12
            binary = "0" + binary
        return ((binary.replace("0","a")).replace("1","0")).replace("a","1")
    
def isInteger(input:str): #returns true if a string value could be an integer
    if input.startswith("-"):
        return input.replace("-","",1).isnumeric()
    else:
        return input.isnumeric()
    
print("source code file:")
inputfile = open(input(), mode='r')
inputtext = inputfile.readlines()
inputfile.close()


compileGood = True
outlist = []#holds all of the final binary instructions
for i in range(4096):
    outline = "" #holds the binary for the current line
    if i < len(inputtext):
        iline = removeChar(removeChar(inputtext[i],","),"\n")# The input string for one line
    else:
        iline = ""
    iline = iline.casefold() #make it lower case
    if len(iline) == 0:
        ilist = []
    else:
        ilist = iline.rsplit(" ")#split the line into a list of strings. Every space is deleted and indicates a new item
    #begin decoding the line
    if len(ilist) == 0 or iline.startswith("/"): #skip empty lines They will just show up as a no op
        outline = "0000" + "0" + "0" + "00" +"000000000000" + "000000000000"
    elif ilist[0] == "nop" and len(ilist) == 1:
        outline = "0000" + "0" + "0" + "00" +"000000000000" + "000000000000"
    elif ilist[0] == "hlt" and len(ilist) == 1:
        outline = "1000" + "0" + "0" + "00" +"000000000000" + "000000000000"
    elif len(ilist) != 3: #all opps from this point forwards should be three things a line
        compileGood = False
        print(ilist)
        print("complile error on line " + str(i+1) + " incorrect number of args")
        break
    elif ilist[0] == "ld":
        #Opcode
        outline = "0001"
        #source type
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + "1"
        else: #memory adrress
            outline = outline + "0"
        #destination type
        outline = outline + "0"
        #CC
        outline = outline + "00"
        #source Address
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + ilist[2]
        else:
            outline = outline + getaddress(ilist[2])
        #destination address
        if isBinary(ilist[1]) and len(ilist[1]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[1]
        else:
            compileGood = False
            print("complile error on line " + str(i+1) + " register index should be in form '0000'")
            break
    elif ilist[0] == "str":
        #Opcode
        outline = "0010"
        #source type
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + "1"
        else: #memory adrress
            outline = outline + "0"
        #destination type
        outline = outline + "0"
        #CC
        outline = outline + "00"
        #Source Adrress
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + ilist[2]
        elif isBinary(ilist[2]) and len(ilist[2]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[2]
        else:
            compileGood = False
            print("compile error on line " + str(i+1) + " register index should be in form '0000'")
            break
        #Destination Adrress
        outline = outline + getaddress(ilist[1])
    elif ilist[0] == "bra":
        #Opcode
        outline = "0011"
        #no source type
        #destination type
        outline = outline + "0"
        #CC
        if ilist[2] == "always":
            outline = outline + "000"
        elif ilist[2] == "parity":
            outline = outline + "001"
        elif ilist[2] == "even":
            outline = outline + "010"
        elif ilist[2] == "carry":
            outline = outline + "011"
        elif ilist[2] == "negative":
            outline = outline + "100"
        elif ilist[2] == "zero":
            outline = outline + "101"
        elif ilist[2] == "no_carry":
            outline = outline + "110"
        elif ilist[2] == "positive":
            outline = outline + "111"
        else:
            compileGood = False
            print("compile error on line " + str(i+1) + " invalid CC")
            break
        #no source address
        outline = outline + "000000000000"
        #destination address aka where the the program will jump to
        #program memorry is stored in 12 bit adresses in PC
        if isInteger(ilist[1]) and int(ilist[1]) >= 0 and int(ilist[1]) < 4096:
            binary = format(int(ilist[1]),'b')
            charsNeeded = 12 - len(binary)
            for x in range(charsNeeded): #append 0s to make the adress length 12
                binary = "0" + binary
            outline = outline + binary
        else: 
            compileGood = False
            print("compile error on line " + str(i+1) + " invalid input for branch destination")
            break
    elif ilist[0] == "xor":
        #Opcode
        outline = "0100"
        #source type
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + "1"
        else: #memory adrress
            outline = outline + "0"
        #destination type
        outline = outline + "0"
        #CC
        outline = outline + "00"
        #Source Adrress
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + ilist[2]
        elif isBinary(ilist[2]) and len(ilist[2]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[2]
        else:
            compileGood = False
            print("compile error on line " + str(i+1) + " register index should be in form '0000'")
            break
        #destination address
        if isBinary(ilist[1]) and len(ilist[1]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[1]
        else:
            compileGood = False
            print("complile error on line " + str(i+1) + " register index should be in form '0000'")
            break
    elif ilist[0] == "add":
        #Opcode
        outline = "0101"
        #source type
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + "1"
        else: #memory adrress
            outline = outline + "0"
        #destination type
        outline = outline + "0"
        #CC
        outline = outline + "00"
        #Source Adrress
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + ilist[2]
        elif isBinary(ilist[2]) and len(ilist[2]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[2]
        else:
            compileGood = False
            print("compile error on line " + str(i+1) + " register index should be in form '0000'")
            break
        #destination address
        if isBinary(ilist[1]) and len(ilist[1]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[1]
        else:
            compileGood = False
            print("complile error on line " + str(i+1) + " register index should be in form '0000'")
            break
    elif ilist[0] == "rot":
        #Opcode
        outline = "0110"
        #source type
        outline = outline + "1"
        #destination type
        outline = outline + "0"
        #CC
        outline = outline + "00"
        #Shift/rotate count
        if isInteger(ilist[2]) and int(ilist[2]) >= -2048 and int(ilist[2]) < 2048:
            outline = outline + twosComplement(int(ilist[2]))
        else: 
            compileGood = False
            print("compile error on line " + str(i+1) + " invalid input for shift. enter decimal value between -2048, 2047")
            break
        #destination address
        if isBinary(ilist[1]) and len(ilist[1]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[1]
        else:
            compileGood = False
            print("complile error on line " + str(i+1) + " register index should be in form '0000'")
            break
    elif ilist[0] == "shf":
        #Opcode
        outline = "0111"
        #source type
        outline = outline + "1"
        #destination type
        outline = outline + "0"
        #CC
        outline = outline + "00"
        #Shift/rotate count
        if isInteger(ilist[2]) and int(ilist[2]) >= -2048 and int(ilist[2]) < 2048:
            outline = outline + twosComplement(int(ilist[2]))
        else: 
            compileGood = False
            print("compile error on line " + str(i+1) + " invalid input for shift. enter decimal value between -2048, 2047")
            break
        #destination address
        if isBinary(ilist[1]) and len(ilist[1]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[1]
        else:
            compileGood = False
            print("complile error on line " + str(i+1) + " register index should be in form '0000'")
            break
    elif ilist[0] == "cmp":
        #Opcode
        outline = "1001"
        #source type
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + "1"
        else: #memory adrress
            outline = outline + "0"
        #destination type
        outline = outline + "0"
        #CC
        outline = outline + "00"
        #Source Adrress
        if isBinary(ilist[2]) and len(ilist[2]) == 12:#hardcoded val
            outline = outline + ilist[2]
        elif isBinary(ilist[2]) and len(ilist[2]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[2]
        else:
            compileGood = False
            print("compile error on line " + str(i+1) + " register index should be in form '0000'")
            break
        #destination address
        if isBinary(ilist[1]) and len(ilist[1]) == 4:#valid registor index
            outline  = outline + "00000000" + ilist[1]
        else:
            compileGood = False
            print("compile error on line " + str(i+1) + " register index should be in form '0000'")
            break
    else:
        compileGood = False
        print("compile error on line " + str(i+1) + " unrecognized opperation")
        break
    outline = outline + "\n"
    outlist.append(outline)



if compileGood:
    print("compile finished, Output file name:")
    outputfile = open(input(), mode='w')
    outputfile.writelines(outlist)
    outputfile.close()

