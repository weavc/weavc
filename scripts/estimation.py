import math

mappings = {
    'XS': 2,
    'S': 3,
    'M': 5,
    'L': 8,
    'XL': 12
}

# O(n^2) for dev scaling, baseline of 0.1 per change
def d(base, devs):
    c = 0.1
    dif = devs-base
    v = (dif**2)*c
    return v

def r(ratings):
    t = 0
    for r in ratings:
        t += mappings[r]
    return t

ratings = ['XL', 'XL', 'L', 'M', 'L', 'L', 'S', 'M', 'M', 'S']
devs = 5

baselines = [{
    'ratings': r(['S', 'L', 'S', 'S', 'L', 'S', 'L', 'S']),
    'weeks': 11,
    'devs': 4
},{
    'ratings': r(['XL', 'L', 'S', 'M', 'M', 'S', 'L', 'S']),
    'weeks': 11,
    'devs': 4
}]

total = r(ratings)

upper = 0
lower = 0
all = []

for baseline in baselines:
    dv = devs-d(devs, baseline['devs'])
    multiple = total/baseline['ratings']
    weeks = ((baseline['weeks']*baseline['devs'])/dv)*multiple
    print(f'Comparing: {baseline} ({dv}, {multiple}, {weeks})')

    all.append(weeks)
    if upper == 0 or upper < weeks:
        upper = weeks
    if lower == 0 or lower > weeks:
        lower = weeks

print(f'Points: {total}')
print(f'Weeks (Upper/Lower/Avg): {math.ceil(upper)} / {math.ceil(lower)} / {math.ceil(sum(all, 0)/len(all))}')



