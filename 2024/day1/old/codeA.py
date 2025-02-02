dataFile = open('input', 'r')

listA = []
listB = []

for line in dataFile:
	line = line.strip('\n')
	parts = line.split('   ')
	listA.append(parts[0])
	listB.append(parts[1])

dataFile.close()

listA.sort()
listB.sort()

dists = [abs(int(listA[i]) - int(listB[i])) for i in range(len(listA))]

dist = 0
for i in range(len(dists)):
	dist+=dists[i]

print(dist)
