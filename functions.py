def nGivenSupportingPop(pop, supPop):
    n = 0
    for i in range(1, pop):
        x = random.randint(1, supPop)
        n = n + (x == supPop)
    return n
