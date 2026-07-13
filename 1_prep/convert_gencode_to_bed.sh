zcat wgEncodeGencodeBasicV39.txt.gz > wgEncodeGencodeBasicV39.txt
cut -f 3,5,6 wgEncodeGencodeBasicV39.txt > wgEncodeGencodeBasicV39.bed.tmp
paste wgEncodeGencodeBasicV39.bed.tmp wgEncodeGencodeBasicV39.txt > wgEncodeGencodeBasicV39.bed.unsort
sort -k1,1 -k2,2n -k3,3n wgEncodeGencodeBasicV39.bed.unsort > wgEncodeGencodeBasicV39.bed
bgzip -f -c wgEncodeGencodeBasicV39.bed > wgEncodeGencodeBasicV39.bed.gz
tabix -p bed wgEncodeGencodeBasicV39.bed.gz

rm wgEncodeGencodeBasicV39.txt
rm wgEncodeGencodeBasicV39.bed.unsort
rm wgEncodeGencodeBasicV39.bed.tmp
rm wgEncodeGencodeBasicV39.bed
