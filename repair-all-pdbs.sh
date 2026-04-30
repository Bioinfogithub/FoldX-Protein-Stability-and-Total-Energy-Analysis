FOLDX_ROTABASE=/apps/scratch/compile/rotabase.txt

mkdir -p repaired_pdbs

for pdb in *.pdb
do
    echo "Repairing $pdb"
    foldx --command=RepairPDB \
          --pdb="$pdb" \
          --rotabaseLocation=$FOLDX_ROTABASE \
          --output-dir="repaired_pdbs"
done
