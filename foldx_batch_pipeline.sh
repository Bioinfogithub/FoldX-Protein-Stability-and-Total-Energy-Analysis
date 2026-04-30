#!/bin/bash

# ============================================================
# FoldX Batch Pipeline
# PDBs : WT.pdb + any number of mutant PDBs
# Outputs: CSV tables in summary/
#
# .fxout column order (verified from raw file):
#   col1  = PDB path
#   col2  = Total
#   col3  = BackHbond
#   col4  = SideHbond
#   col5  = Energy_VdW
#   col6  = Electro
#   col7  = Energy_SolvP
#   col8  = Energy_SolvH
#   col9  = Energy_vdwclash
#   col10 = Entropy_sidec
#   col11 = Entropy_mainc
#   col12 = water_bonds
#   col13 = helix_dipole
#   col14 = loop_entropy
#   col15 = energy_torsion
#   col16 = backbone_vdwclash
#   col17 = cis_bond
#   col18 = disulfide
#   col19 = kn_electrostatic
#   col20 = partial_covalent
#   col21 = Entropy_Complex
#   col22 = Energy_Ionisation
#   col23 = (unused/zero)
#   col24 = residue count (skip)
# ============================================================

FOLDX_ROTABASE="/apps/scratch/compile/rotabase.txt"

# Correct term names mapped to file columns 2..23
TERM_NAMES=(
    "Total"
    "BackHbond"
    "SideHbond"
    "Energy_VdW"
    "Electro"
    "Energy_SolvP"
    "Energy_SolvH"
    "Energy_vdwclash"
    "Entropy_sidec"
    "Entropy_mainc"
    "water_bonds"
    "helix_dipole"
    "loop_entropy"
    "energy_torsion"
    "backbone_vdwclash"
    "cis_bond"
    "disulfide"
    "kn_electrostatic"
    "partial_covalent"
    "Entropy_Complex"
    "Energy_Ionisation"
)

if [ ! -f "$FOLDX_ROTABASE" ]; then
    echo "ERROR: rotabase.txt not found at $FOLDX_ROTABASE"
    exit 1
fi

mkdir -p repaired_pdbs stability_results summary

# ============================================================
# STEP 1: Repair all PDBs
# ============================================================
echo ""
echo "===== STEP 1: Repairing PDBs ====="

for pdb in *.pdb; do
    echo "  Repairing: $pdb"
    foldx --command=RepairPDB \
          --pdb="$pdb" \
          --rotabaseLocation="$FOLDX_ROTABASE" \
          --output-dir="repaired_pdbs"
done

echo "  Done. Repaired PDBs saved in: repaired_pdbs/"

# ============================================================
# STEP 2: Stability for each repaired PDB
# ============================================================
echo ""
echo "===== STEP 2: Calculating Stability ====="

for pdb in repaired_pdbs/*_Repair.pdb; do
    [ -f "$pdb" ] || continue

    filename=$(basename "$pdb")
    dirpath=$(dirname "$pdb")
    base=$(basename "$pdb" _Repair.pdb)

    mkdir -p stability_results/$base

    echo "  Running Stability: $base"

    foldx --command=Stability \
          --pdb="$filename" \
          --pdb-dir="$dirpath" \
          --rotabaseLocation="$FOLDX_ROTABASE" \
          --output-dir="stability_results/$base"
done

echo "  Done. Results saved in: stability_results/"

# ============================================================
# STEP 3: Parse .fxout → CSV tables
#
# Each .fxout has exactly ONE data line (no header).
# col1=path  col2=Total  col3..col22=energy terms  col24=residue count
# ============================================================
echo ""
echo "===== STEP 3: Extracting Energy Tables ====="

TOTAL_CSV="summary/total_energy_summary.csv"
echo "Protein,TotalEnergy(kcal/mol)" > "$TOTAL_CSV"

for file in stability_results/*/*_Repair_0_ST.fxout; do
    [ -f "$file" ] || continue

    base=$(basename "$file" _Repair_0_ST.fxout)

    # Read the single data line
    dataline=$(head -1 "$file")

    if [ -z "$dataline" ]; then
        echo "  WARNING: Empty file: $file"
        continue
    fi

    # Split by tab into array
    IFS=$'\t' read -ra COLS <<< "$dataline"
    # COLS[0]=path, COLS[1]=Total, COLS[2..21]=other terms, COLS[22]=unused, COLS[23]=residues

    # --- Write full stability CSV for this PDB (terms in display order) ---
    out="summary/${base}_stability_full.csv"
    echo "EnergyTerm,Value(kcal/mol)" > "$out"

    for i in "${!TERM_NAMES[@]}"; do
        term="${TERM_NAMES[$i]}"
        value="${COLS[$((i + 1))]}"   # +1 because COLS[0] is the path
        echo "$term,$value" >> "$out"
    done

    echo "  Written: $out"

    # --- Total energy (COLS[1]) into summary ---
    total="${COLS[1]}"
    echo "$base,$total" >> "$TOTAL_CSV"
    echo "  $base  -->  Total = $total kcal/mol"
done

echo ""
echo "  Total energy summary: $TOTAL_CSV"

# ============================================================
# STEP 4: ddG = Mutant_Total - WT_Total
# ============================================================
echo ""
echo "===== STEP 4: Calculating ddG ====="

wt_energy=$(grep "^WT," "$TOTAL_CSV" | cut -d',' -f2)

if [ -z "$wt_energy" ]; then
    echo "  ERROR: WT not found in $TOTAL_CSV"
    echo "         Make sure WT.pdb is in your working directory."
    exit 1
fi

echo "  WT Total Energy = $wt_energy kcal/mol"

DDG_CSV="summary/ddG_table.csv"
echo "Protein,TotalEnergy(kcal/mol),WT_Energy(kcal/mol),DeltaDeltaG(kcal/mol)" > "$DDG_CSV"

while IFS=',' read -r name energy; do
    [ "$name" = "Protein" ] && continue
    [ "$name" = "WT" ]      && continue

    ddg=$(echo "scale=3; $energy - ($wt_energy)" | bc)
    echo "$name,$energy,$wt_energy,$ddg" >> "$DDG_CSV"
    echo "  $name  -->  ddG = $ddg kcal/mol"

done < "$TOTAL_CSV"

echo "  ddG table: $DDG_CSV"

# ============================================================
# DONE
# ============================================================
echo ""
echo "===== ALL DONE ====="
echo ""
echo "Output files in summary/:"
ls summary/
