for pdb in *.pdb
do
    base=$(basename "$pdb" .pdb)
    mkdir -p foldx_results/$base
    
    foldx --command=Stability \
          --pdb="$pdb" \
          --output-dir="foldx_results/$base"
done
