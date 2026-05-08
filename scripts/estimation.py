import math


# O(n^2) for dev scaling, rate of change 0.1 per dev different from the baseline
# The value for c is just a guess but feels about right for variants of 1-3 people
def d(base, devs):
    c = 0.1
    dif = devs-base
    v = (dif**2)*c
    if dif > 0:
        v = -v
    return v

# points from ratings
def r(ratings):
    t = 0
    for k in ratings.keys():
        t += ratings[k]*mappings[k]
    return t

# points per size
mappings = {
    'XS': 2,
    'S': 3,
    'M': 5,
    'L': 8,
    'XL': 12
}
devs = [2, 3, 4, 5, 6]
# Sizes
ratings = {
    'XS': 0,
    'S': 2,
    'M': 3,
    'L': 3,
    'XL': 2
}

baselines = [
    {
        'ratings': r({'S': 5, 'L': 3}),
        'weeks': 11,
        'devs': 4
    },
    {
        'ratings': r({'XL': 1, 'L': 2, 'M': 2, 'S': 3}),
        'weeks': 11,
        'devs': 4
    }
]

total = r(ratings)
print(f'Points: {total}')

for dev in devs:
    results = []
    for baseline in baselines:
        dv = dev+d(baseline['devs'], dev)
        multiple = total/baseline['ratings']
        weeks = ((baseline['weeks']*baseline['devs'])/dv)*multiple
        results.append(weeks)
    print(f'{dev} Devs, Weeks (Upper/Lower/Avg): {math.ceil(max(results))} / {math.ceil(min(results))} / {math.ceil(sum(results, 0)/len(results))}')




