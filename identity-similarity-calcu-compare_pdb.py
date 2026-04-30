#!/usr/bin/env python3

import glob

AA = {
    'ALA':'A','ARG':'R','ASN':'N','ASP':'D','CYS':'C',
    'GLN':'Q','GLU':'E','GLY':'G','HIS':'H','ILE':'I',
    'LEU':'L','LYS':'K','MET':'M','PHE':'F','PRO':'P',
    'SER':'S','THR':'T','TRP':'W','TYR':'Y','VAL':'V',
    'HSD':'H','HSE':'H','HSP':'H','HID':'H','HIE':'H','HIP':'H',
}

def get_seq(pdb_file):
    seq = []
    seen = set()
    with open(pdb_file) as f:
        for line in f:
            if line.startswith("ATOM") and line[12:16].strip() == "CA":
                chain  = line[21]
                resnum = line[22:26].strip()
                resname= line[17:20].strip()
                key    = (chain, resnum)
                if key not in seen:
                    seen.add(key)
                    seq.append(AA.get(resname, 'X'))
    return "".join(seq)

def score(s1, s2):
    pairs = list(zip(s1, s2))
    total = len(pairs)
    if total == 0:
        return 0, 0
    identity = sum(a == b for a, b in pairs)
    similar_groups = [
        set('KRH'), set('DE'), set('STNQ'),
        set('LIVM'), set('FYW'), set('AG'), set('CP')
    ]
    def is_similar(a, b):
        if a == b: return True
        return any(a in g and b in g for g in similar_groups)
    similarity = sum(is_similar(a, b) for a, b in pairs)
    return round(100*identity/total, 2), round(100*similarity/total, 2)

# ── Run ───────────────────────────────────────────────────────────
wt_seq = get_seq("WT_Repair.pdb")
print(f"WT sequence length: {len(wt_seq)} residues")
print(f"WT sequence: {wt_seq}\n")

print(f"{'File':<30} {'Length':>6} {'Identity%':>10} {'Similarity%':>12}")
print("-" * 62)

results = []
for pdb in sorted(glob.glob("*.pdb")):
    if pdb == "WT_Repair.pdb":
        continue
    seq = get_seq(pdb)
    idt, sim = score(wt_seq, seq)
    results.append((pdb, len(seq), idt, sim))
    print(f"{pdb:<30} {len(seq):>6} {idt:>9.2f}% {sim:>11.2f}%")

# Save to CSV
with open("results.csv", "w") as f:
    f.write("File,Length,Identity%,Similarity%\n")
    for r in results:
        f.write(f"{r[0]},{r[1]},{r[2]},{r[3]}\n")

print("\nSaved to results.csv")
