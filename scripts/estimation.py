import math

mappings = {
    'XS': 2,
    'S': 3,
    'M': 5,
    'L': 8,
    'XL': 12
}

# O(n^2) for dev scaling, rate of change 0.1 per dev different from the baseline
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
    for r in ratings:
        t += mappings[r]
    return t

devs = [2, 3, 4, 5, 6]
ratings = ['XL', 'XL', 'L', 'M', 'L', 'L', 'S', 'M', 'M', 'S']

baselines = [
    {
        'ratings': r(['S', 'L', 'S', 'S', 'L', 'S', 'L', 'S']),
        'weeks': 11,
        'devs': 4
    },
    {
        'ratings': r(['XL', 'L', 'S', 'M', 'M', 'S', 'L', 'S']),
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
        # print(f'Comparing: {baseline} ({dv}, {multiple}, {weeks})')
    print(f'{dev} Devs, Weeks (Upper/Lower/Avg): {math.ceil(max(results))} / {math.ceil(min(results))} / {math.ceil(sum(results, 0)/len(results))}')




