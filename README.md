# FoldX Protein Stability and Total Energy Analysis

A reproducible computational workflow for evaluating protein structural stability and energetic changes using **FoldX**.

This repository documents the preparation of protein structures, FoldX energy/stability calculations, extraction of total energy terms, and interpretation of FoldX output for protein stability analysis.

---

## 1. Overview

**FoldX** is an empirical force field designed to estimate the energetic consequences of protein structural changes, including amino-acid substitutions. FoldX evaluates contributions from several energetic terms, including van der Waals interactions, hydrogen bonding, electrostatics, solvation, steric clashes, torsional effects, and conformational entropy.

The central workflow used in this repository is:

```text
Protein Structure (.pdb)
        |
        v
Structure Preparation
        |
        v
FoldX RepairPDB
        |
        v
Repaired Protein Structure
        |
        v
FoldX Stability Analysis
        |
        v
Energetic Components
        |
        v
Total Energy / Stability
        |
        v
Result Extraction
        |
        v
Comparison and Interpretation
```

The workflow can be extended to mutation-specific analyses using FoldX `BuildModel` and related commands.

---

## 2. Objectives

The workflow is intended to:

- Prepare protein structures for FoldX analysis.
- Repair and optimize protein structures before energetic calculations.
- Calculate FoldX stability/energy terms.
- Extract the total energy from FoldX output.
- Compare energetic profiles between protein structures or variants.
- Support structure-based interpretation of protein stability.
- Provide a reproducible command-line workflow that can be adapted for batch analysis.

---

## 3. Software and Tools

### Core software

| Software | Purpose |
|---|---|
| **FoldX** | Protein energy and stability calculations |
| **Linux / Unix shell** | Command-line workflow |
| **Bash** | Automation and batch processing |
| **Python** | Optional result processing and visualization |
| **GROMACS / MD tools** | Optional downstream structural analysis |
| **PyMOL / VMD** | Optional structural inspection |

### FoldX

FoldX must be obtained from the official FoldX distribution and used according to its licensing requirements.

> **Important:** FoldX is not distributed with this repository. The executable must be installed separately.

---

## 4. Requirements

Before starting the analysis, ensure that:

1. FoldX is installed.
2. The FoldX executable has execute permission.
3. A valid protein structure in PDB format is available.
4. The PDB structure contains correctly assigned residue and chain identifiers.
5. Required non-standard molecules are appropriately parametrized if present.
6. The working directory is writable.

Check the FoldX installation:

```bash
./foldx --help
```

or, depending on the executable name:

```bash
/path/to/foldx --help
```

---

# 5. Input Structure

FoldX requires a protein structure in PDB format.

Example:

```text
input/
└── protein.pdb
```

Before analysis, inspect the structure for:

- Missing residues
- Missing atoms
- Incorrect chain identifiers
- Alternate locations
- Unusual residue names
- Missing side chains
- Non-standard ligands or cofactors
- Incorrect residue numbering

Structural inspection can be performed using PyMOL, VMD, Chimera/ChimeraX, or another molecular visualization program.

---

# 6. Recommended Working Directory

A simple project organization is:

```text
FoldX-Protein-Stability-and-Total-Energy-Analysis/
│
├── README.md
│
├── input/
│   └── protein.pdb
│
├── foldx/
│   └── foldx
│
├── repair/
│
├── stability/
│
├── mutations/
│
├── results/
│
└── scripts/
    ├── run_repair.sh
    ├── run_stability.sh
    └── extract_total_energy.sh
```

Only include files that are actually used by the project. Large FoldX output files and executable binaries generally should not be committed to GitHub.

---

# 7. Step 1 — Prepare the PDB Structure

Place the input structure in the working directory.

Example:

```bash
mkdir -p input repair stability results
cp protein.pdb input/
```

Check the structure:

```bash
grep "^ATOM" input/protein.pdb | head
```

Check the number of ATOM records:

```bash
grep -c "^ATOM" input/protein.pdb
```

Inspect chains:

```bash
awk '$1=="ATOM"{print $5}' input/protein.pdb | sort -u
```

The exact PDB preparation required depends on the structure being studied.

---

# 8. Step 2 — Run FoldX RepairPDB

Before calculating stability, it is generally recommended to repair the structure using FoldX.

The `RepairPDB` command optimizes local side-chain conformations and hydrogen-bonding networks and helps prepare the structure for subsequent FoldX calculations.

Basic command:

```bash
./foldx --command=RepairPDB --pdb=protein.pdb
```

Depending on the FoldX installation:

```bash
/path/to/foldx --command=RepairPDB --pdb=protein.pdb
```

A repaired structure is typically generated with a name similar to:

```text
protein_Repair.pdb
```

Move or copy the repaired structure to the repair directory:

```bash
mv protein_Repair.pdb repair/
```

---

# 9. Step 3 — Inspect the Repaired Structure

The repaired structure should be inspected before proceeding.

```bash
ls repair/
```

Expected:

```text
repair/
└── protein_Repair.pdb
```

Open the repaired PDB in PyMOL, VMD, Chimera, or ChimeraX if structural inspection is required.

---

# 10. Step 4 — FoldX Stability Analysis

The FoldX `Stability` command calculates the energetic stability of a protein structure.

Basic command:

```bash
./foldx \
    --command=Stability \
    --pdb=protein_Repair.pdb
```

For a FoldX executable located elsewhere:

```bash
/path/to/foldx \
    --command=Stability \
    --pdb=protein_Repair.pdb
```

FoldX produces energetic terms including contributions such as:

```text
BackHbond
SideHbond
Energy_VdW
Electro
Energy_SolvP
Energy_SolvH
Energy_vdwclash
energy_torsion
backbone_vdwclash
Entropy_sidec
Entropy_mainc
water bonds
helix dipole
loop_entropy
cis_bond
disulfide
Energy_Ionisation
Entropy Complex
Total
```

The exact output fields can vary with FoldX version and command.

---

# 11. FoldX Total Energy

The `Total` term is the overall energetic value reported by the FoldX stability calculation.

A typical output contains:

```text
-----------------------------------------------------------
Total          =              XXXXX.XX
```

Extract the total energy from a FoldX output file:

```bash
grep "Total          =" *.out
```

For a specific output:

```bash
grep "Total          =" protein_Repair_ST.fxout
```

---

# 12. Batch Analysis of Multiple Structures

For multiple PDB structures:

```bash
for f in *.pdb
do
    ./foldx --command=RepairPDB --pdb="$f"
done
```

After repair:

```bash
for f in *_Repair.pdb
do
    ./foldx --command=Stability --pdb="$f"
done
```

The exact FoldX output filenames depend on the FoldX version and execution environment.

---

# 13. Extract Total Energy for Multiple Structures

A simple Bash workflow can collect total energy values.

```bash
for f in *.out
do
    echo "$f"
    grep "Total          =" "$f"
done
```

For a tab-separated summary:

```bash
for f in *.out
do
    total=$(grep "Total          =" "$f" | awk '{print $3}')
    echo -e "${f}\t${total}"
done
```

Example output:

```text
WT.out        152.49
Mutant1.out   148.31
Mutant2.out   161.27
```

The values above are illustrative only.

---

# 14. Generate a Result Table

A useful summary table can contain:

| Structure | FoldX Total Energy (kcal/mol) | Difference from WT |
|---|---:|---:|
| WT | ... | 0.00 |
| Mutant 1 | ... | ... |
| Mutant 2 | ... | ... |
| Mutant 3 | ... | ... |

The difference can be calculated as:

```text
ΔE = E_variant − E_WT
```

For automated processing, Python or R can be used to parse FoldX output files.

---

# 15. Interpreting FoldX Energy

FoldX reports energetic quantities in **kcal/mol**.

For comparative analyses, the same FoldX version and consistent settings should be used across all structures.

When comparing structures:

```text
ΔE = E_variant − E_reference
```

For mutation-specific stability calculations, a commonly used quantity is:

```text
ΔΔG = ΔG_mutant − ΔG_WT
```

The sign and interpretation should always be considered together with the exact FoldX command, output definition, structural preparation, and comparison being performed.

**Do not interpret a single FoldX total-energy value as an experimental measurement of thermodynamic stability.** FoldX provides an empirical computational estimate.

---

# 16. Energetic Components

FoldX decomposes the calculated energy into multiple terms.

Important components may include:

### Van der Waals interactions

```text
Energy_VdW
```

Describes the contribution associated with van der Waals interactions.

### Hydrogen bonding

```text
BackHbond
SideHbond
```

Reports backbone and side-chain hydrogen-bond contributions.

### Electrostatics

```text
Electro
```

Represents electrostatic interactions.

### Polar and apolar solvation

```text
Energy_SolvP
Energy_SolvH
```

These terms describe solvation-related energetic contributions.

### Steric clashes

```text
Energy_vdwclash
backbone_vdwclash
```

These terms identify unfavorable steric interactions.

### Torsional contribution

```text
energy_torsion
```

Accounts for torsional energetic contributions.

### Entropy

```text
Entropy_sidec
Entropy_mainc
```

These terms describe side-chain and main-chain entropy contributions within the FoldX energy model.

---

# 17. Mutation Analysis with BuildModel

FoldX can also be used to estimate the energetic effect of specific amino-acid substitutions.

A mutation list can be prepared using FoldX mutation notation.

Example:

```text
A135K;
```

where:

```text
A = chain
135 = residue position
K = mutant residue
```

The exact mutation format should match the structure's chain and residue numbering.

A typical `BuildModel` command is:

```bash
./foldx \
    --command=BuildModel \
    --pdb=protein_Repair.pdb \
    --mutant-file=individual_list.txt
```

The resulting mutant structures and FoldX energy outputs can then be analyzed relative to the corresponding wild-type structure.

---

# 18. Mutation Workflow

For mutation-based stability analysis:

```text
WT Protein Structure
        |
        v
PDB Quality Check
        |
        v
FoldX RepairPDB
        |
        v
Repaired WT Structure
        |
        v
Define Mutation
        |
        v
BuildModel
        |
        v
Mutant Structure
        |
        v
FoldX Energy Calculation
        |
        v
WT vs Mutant Comparison
        |
        v
ΔΔG / Energy Analysis
```

---

# 19. Multiple Mutation Analysis

For multiple mutations, prepare a mutation file according to FoldX syntax.

Example:

```text
A135K;
A142R;
B210Y;
```

Then run:

```bash
./foldx \
    --command=BuildModel \
    --pdb=protein_Repair.pdb \
    --mutant-file=individual_list.txt
```

For multiple independent mutations, maintain clear naming and metadata so that each output can be traced back to the corresponding mutation.

---

# 20. Protein Complexes

FoldX can also be applied to protein complexes.

For complex analysis:

```text
Protein–Protein Complex
        |
        v
Structure Preparation
        |
        v
RepairPDB
        |
        v
Stability / Interaction Analysis
        |
        v
Energy Decomposition
        |
        v
WT vs Mutant Comparison
```

For interface studies, the FoldX analysis should be interpreted together with structural/interface information such as:

- Hydrogen bonds
- Salt bridges
- Van der Waals contacts
- Interface residues
- Buried surface area
- Structural rearrangements
- Molecular dynamics results

FoldX should therefore be treated as one component of a broader computational analysis rather than as an independent experimental validation.

---

# 21. Quality Control

Before accepting FoldX results, check:

### Structure

- Correct chain IDs
- Correct residue numbering
- No unexpected missing residues
- No severe structural artifacts
- Correct mutation positions
- Appropriate treatment of ligands/cofactors

### FoldX execution

Check that FoldX reports successful completion:

```bash
grep -i "finish" *.out
```

Inspect warnings:

```bash
grep -i "warning" *.out
```

Also inspect messages related to:

```text
External parametrized molecules
```

If non-standard molecules are present, their parametrization can affect the resulting energies.

---

# 22. Reproducibility

For reproducible FoldX calculations, record:

- FoldX version
- Operating system
- Input PDB identifier/file
- Structure preparation procedure
- Chain IDs
- Residue numbering
- Mutation definitions
- FoldX command
- Calculation date
- Output files
- Any non-standard molecule parametrization
- Scripts used for result extraction

Example:

```text
FoldX version: FoldX 5.x
Input structure: protein.pdb
Command: Stability
Structure preparation: RepairPDB
Analysis: Total energy comparison
```

Avoid mixing results generated using substantially different FoldX versions or preparation protocols without explicitly documenting the difference.

---

# 23. Suggested Repository Organization

A clean repository can follow:

```text
FoldX-Protein-Stability-and-Total-Energy-Analysis/
│
├── README.md
│
├── input/
│   ├── README.md
│   └── *.pdb
│
├── repair/
│   └── README.md
│
├── mutations/
│   ├── README.md
│   └── individual_list.txt
│
├── scripts/
│   ├── run_repair.sh
│   ├── run_stability.sh
│   ├── run_buildmodel.sh
│   └── extract_total_energy.sh
│
├── results/
│   ├── README.md
│   └── summary.tsv
│
└── figures/
    └── README.md
```

Use the structure above only where the corresponding files actually exist in the project.

---

# 24. Example Automation Script

A minimal stability-analysis script:

```bash
#!/bin/bash

FOLDX="/path/to/foldx"
PDB="protein_Repair.pdb"

"$FOLDX" \
    --command=Stability \
    --pdb="$PDB"
```

Save as:

```text
scripts/run_stability.sh
```

Make executable:

```bash
chmod +x scripts/run_stability.sh
```

Run:

```bash
./scripts/run_stability.sh
```

---

# 25. Example Total-Energy Extraction Script

```bash
#!/bin/bash

mkdir -p results

echo -e "File\tTotal_Energy_kcal_mol" > results/foldx_total_energy.tsv

for f in *.out
do
    total=$(grep "Total          =" "$f" | awk '{print $3}')

    if [ -n "$total" ]
    then
        echo -e "${f}\t${total}" >> results/foldx_total_energy.tsv
    fi
done
```

Output:

```text
results/foldx_total_energy.tsv
```

---

# 26. Optional Python Analysis

A simple Python script can load the extracted table:

```python
import pandas as pd

df = pd.read_csv(
    "results/foldx_total_energy.tsv",
    sep="\t"
)

print(df)

df.to_csv(
    "results/foldx_total_energy.csv",
    index=False
)
```

For visualization:

```python
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv(
    "results/foldx_total_energy.tsv",
    sep="\t"
)

plt.figure(figsize=(8, 5))
plt.bar(df["File"], df["Total_Energy_kcal_mol"])
plt.ylabel("FoldX Total Energy (kcal/mol)")
plt.xticks(rotation=45, ha="right")
plt.tight_layout()
plt.show()
```

---

# 27. Common Problems and Troubleshooting

## Problem 1 — FoldX executable cannot be run

Check permissions:

```bash
chmod +x foldx
```

Then:

```bash
./foldx --help
```

---

## Problem 2 — Residue not found

Check the PDB residue numbering and chain identifier:

```bash
grep "^ATOM" protein.pdb | less
```

Confirm that the mutation notation corresponds exactly to the PDB structure.

For example, if the mutation is:

```text
A135K
```

verify that:

- Chain `A` exists.
- Residue `135` exists.
- The wild-type residue is the expected amino acid.

---

## Problem 3 — External molecules detected

FoldX may report that external parametrized molecules are present.

Inspect the FoldX output carefully and verify that ligands, cofactors, metals, or other non-standard molecules have appropriate parameters.

Do not ignore such warnings when they can influence the energetic calculation.

---

## Problem 4 — Unexpected energy values

Check:

1. Input structure quality.
2. Whether RepairPDB was performed.
3. FoldX version.
4. Chain/residue numbering.
5. Presence of ligands or cofactors.
6. Structural clashes.
7. Whether WT and mutant structures were treated consistently.

---

# 28. Best-Practice Analysis Workflow

For a robust protein stability study:

```text
              INPUT STRUCTURE
                    |
                    v
             STRUCTURE QC
                    |
                    v
              RepairPDB
                    |
                    v
          REPAIRED STRUCTURE
                    |
          +---------+---------+
          |                   |
          v                   v
      WT Stability        Mutation Design
          |                   |
          |                BuildModel
          |                   |
          |                   v
          |              Mutant Structure
          |                   |
          +---------+---------+
                    |
                    v
          FOLDX ENERGY ANALYSIS
                    |
                    v
       TOTAL ENERGY / ΔΔG VALUES
                    |
                    v
        STRUCTURAL INTERPRETATION
                    |
                    v
       EXPERIMENTAL / MD VALIDATION
```

Where possible, FoldX predictions should be integrated with structural analysis, molecular dynamics, experimental measurements, or other independent computational methods.

---

# 29. Important Interpretation Notes

FoldX values are **model-based computational estimates**, not direct experimental measurements.

Therefore:

- Do not equate FoldX total energy directly with experimentally measured unfolding free energy.
- Compare structures using consistent protocols.
- Interpret mutation effects in structural context.
- Consider uncertainty and limitations of empirical energy functions.
- Use experimental data when available for validation.
- For protein complexes, distinguish folding stability from binding/interface energetics.

---

# 30. References

### FoldX 5.0

Delgado, J.; Radusky, L. G.; Cianferoni, D.; Serrano, L. **FoldX 5.0: Working with RNA, Small Molecules and a New Graphical Interface.** *Bioinformatics* **2019**, *35*, 4168–4169.  
DOI: 10.1093/bioinformatics/btz184.

### Original FoldX Web Server

Schymkowitz, J.; Borg, J.; Stricher, F.; Nys, R.; Rousseau, F.; Serrano, L. **The FoldX Web Server: An Online Force Field.** *Nucleic Acids Research* **2005**, *33*, W382–W388.  
DOI: 10.1093/nar/gki387.

### FoldX Documentation

Official FoldX documentation and software distribution:

https://foldxsuite.crg.eu/

---

# 31. Citation

If this repository is used in a publication, cite the FoldX methodology and the specific computational study associated with the repository.

Suggested software citation:

```text
Delgado, J.; Radusky, L. G.; Cianferoni, D.; Serrano, L.
FoldX 5.0: Working with RNA, Small Molecules and a New Graphical Interface.
Bioinformatics 2019, 35, 4168–4169.
```

---

# 32. Author

**Amar Jeet Yadav**  
PhD Research Scholar  
School of Biochemical Engineering  
IIT (BHU), Varanasi, India

GitHub:  
https://github.com/Bioinfogithub

---

## Summary

This repository provides a structured workflow for using FoldX to:

1. Prepare protein structures.
2. Repair structures using `RepairPDB`.
3. Calculate FoldX stability and energetic terms.
4. Extract total energy values.
5. Compare WT and mutant structures.
6. Analyze mutation-associated energetic changes.
7. Organize computational results reproducibly.

The workflow can be integrated with molecular dynamics, structural bioinformatics, docking, and experimental characterization to obtain a broader understanding of protein stability and sequence–structure relationships.
