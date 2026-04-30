for pdb in repaired_pdbs/*_Repair.pdb
do
    base=$(basename "$pdb" _Repair.pdb)
    mkdir -p stability_results/$base

    echo "Running Stability for $base"
    echo "Using rotabase: $FOLDX_ROTABASE"   # debug line

    foldx --command=Stability \
          --pdb="$pdb" \
          --rotabaseLocation=$FOLDX_ROTABASE \
          --output-dir="stability_results/$base"

done
