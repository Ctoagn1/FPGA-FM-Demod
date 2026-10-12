import math 
def main():
    for i in range(10):
        x = math.atan2( (2 ** (-i)), 1)
        if (x < 0):
            x = math.tau + x
        x = x / (math.tau) * (2**16)
        print(x)

main()
