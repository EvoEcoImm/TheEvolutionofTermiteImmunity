~/opt/evigene19jan01/scripts/prot/tr2aacds.pl -mrnaseq $assembly_Trinity.fasta

#reduce redundance of predicted proteins
#cd-hit -i bo_full_trinity.Trinity.fasta.transdecoder.pep -c 1 -n 5 -o bo_dd.pep -d 0 -T 4 -M 10000
#cd-hit -i cm_full_trinity.Trinity.fasta.transdecoder.pep -c 1 -n 5 -o cm_dd.pep -d 0 -T 4 -M 10000
#cd-hit -i nc_full_trinity.Trinity.fasta.transdecoder.pep -c 1 -n 5 -o nc_dd.pep -d 0 -T 4 -M 10000

##--fsa align database building--##
for i in `cat familynames`; do
fsa --stockholm --fast --noindel2 --logtime "$i".fasta > "$i".fasta.aligned
sed '1a\#=GF ID $i' "$i".fasta.aligned >"$i".fixed;
done
cat *.fixed > orthodb.sto
hmmbuild orthodb.hmm orthodb.sto

##--clustalo database building--##
for i in `cat familynames`; do clustalo -i "$i".fa -o ../clustaloalign/"$i".clustalo1.alin --outfmt=st;sed "1a\#=GF ID $i" "$i".clustalo1.alin >> orthodbclusto.sto; done
hmmbuild orthodbclusto.hmm orthodbclusto.sto

##--protein blast database building--##
cat *.fasta > orthodb.fa
makeblastdb -in orthodb.fa -dbtype prot

#Hmmsearch for protein set-qual
for i in `cat samplename`; do hmmsearch -o "$i".out --domtblout "$i".dom_out.tab --tblout "$i".target_out.tab --noali --notextw -E 1e-5 --domE 1 --incE 0.001 --cpu 4 /media/shulinhe/DATA/immune_database/orthodb_v6/orthodbclusto.hmm /media/shulinhe/DATA/QuanL/Transdecoder/"$i"_Trinity.fasta.transdecoder.pep; done

#Hmmsearch for evidential protein set-qual
for i in `cat samplename`; do hmmsearch -o "$i".e.out --domtblout "$i".e.dom_out.tab --tblout "$i".e.target_out.tab --noali --notextw -E 1e-5 --domE 1 --incE 0.001 --cpu 1 /media/shulinhe/DATA/immune_database/orthodb_v6/orthodbclusto.hmm "$i"_Trinity.okay.aa; done

#Blastx for redundanced protein set
#blastx -query bo_Trinity.fasta -db orthodb.fa -num_threads 12 -evalue 0.00001 -max_target_seqs 1 -outfmt 6 -out bo_orthodb.blastx.outfmt6
#Blastp for protein set
for i in `cat samplename`; do sed '/^#/d' "$i".target_out.tab |sed 's/  */ /g'|cut -f1 -d " "|sort -u > linshi.id; xargs samtools faidx /media/shulinhe/DATA/QuanL/Transdecoder/"$i"_Trinity.fasta.transdecoder.pep < linshi.id >> "$i".pep;
blastp -query "$i".pep -db /media/shulinhe/DATA/immune_database/orthodb_v6/Immune_v6.fa -num_threads 3 -evalue 0.00001 -max_target_seqs 1 -outfmt 6 -out "$i".db6.blastp.outfmt6; rm "$i".pep; done

for i in `cat samplename`; do sed '/^#/d' "$i".e.target_out.tab |sed 's/  */ /g'|cut -f1 -d " "|sort -u > linshi.id; xargs samtools faidx "$i"_Trinity.okay.aa < linshi.id >> "$i".pep;
blastp -query "$i".pep -db /media/shulinhe/DATA/immune_database/orthodb_v6/Immune_v6.fa -num_threads 3 -evalue 0.00001 -max_target_seqs 1 -outfmt 6 -out "$i".e.db6.blastp.outfmt6; rm "$i".pep; done

##prepared trinotate output, gene2family, fasta files-qual
for i in `cat samplename`; do
../Immune_curate.py -i "$i".target_out.tab -p "$i".db6.blastp.outfmt6 -t /media/shulinhe/DATA/QuanL/Trinotate_out/"$i"_trinotate_annotation_report.xls -g2f /media/shulinhe/DATA/immune_database/orthodb_v6/Immunedbv6gene2family -f /media/shulinhe/DATA/QuanL/Assembly/"$i"_Trinity.fasta -o "$i"_immune_curate; done

##prepared trinotate output, gene2family, fasta files-qual reduced evidential
for i in `cat samplename`; do
../Immune_curate_evidential.py -i "$i".e.target_out.tab -p "$i".e.db6.blastp.outfmt6 -t /media/shulinhe/DATA/QuanL/Trinotate_out/"$i"_trinotate_annotation_report.xls -g2f /media/shulinhe/DATA/immune_database/orthodb_v6/Immunedbv6gene2family -o "$i"_e_immune_curate; done

#quant
for i in {"cm","bo","nc"}; do hmmsearch -o "$i".out --domtblout "$i".dom_out.tab --tblout "$i".target_out.tab --noali --notextw -E 1e-5 --domE 1 --incE 0.001 --cpu 1 /media/shulinhe/DATA/immune_database/orthodb_v6/orthodbclusto.hmm "$i"; done

../Immune_curate.py -i "$i".target_out.tab -p "$i"_full_orthov6.blastp.outfmt6 -t /media/shulinhe/DATA/Full_analysis/Bo_full/bo_full_trinotate_annotation_report.xls -g2f /media/shulinhe/DATA/immune_database/orthodb_v6/Immunedbv6gene2family -f /media/shulinhe/DATA/Full_analysis/Bo_full/"$i"_full_trinity.Trinity.fasta -o "$i"_immune_curate

#cat immune genes and manually check
for i in `cat samplename`; do awk -v a="$i" '{print a "\t" $0}' "$i"_immune_curate >> ../all_db6_immune_precheck;done
for i in `cat samplename`; do awk -v a="$i" '{print a "\t" "evidential" "\t" $0}' "$i"_e_immune_curate >> ../all_db6_immune_precheck;done
for i in {"nc","cm","bo"}; do awk -v a="$i" '{print a "quant" "\t" $0}' "$i"_immune_curate >> ../all_db6_immune_precheck;done
awk -F'\t' 'BEGIN{OFS="\t"}{print ".", ".",$1,$2,$3,$4,".",".",".",$6,".",$7,$8,"NA",".",".",".","."}' Genome_immune_non >> ../all_db6_immune_precheck

##replace uniprot name with uniport gene name
cut -f12 all_db6_immune_precheck |sort -u |sed '/^\.$/d' > linshiuniprotid
python uniprotparse.py 
awk -F'\t' 'BEGIN{OFS="\t"}FNR==NR{a[$1]=$2"|"$3;next}{$14=a[$12];print}' uniprotfamilydescription all_db6_immune_precheck >all_db6_immune_precheckid; rm linshiuniprotid


##----------------------------------------------------------------------------##
#########################   Manually check  ####################################
##----------------------------------------------------------------------------##
#Summary by R
library(dplyr)
library(tidyr)
all<- read.csv("all_db6_immune_checkid_family_manrefine.csv",header=F,sep="\t",stringsAsFactors=F)
all[grep("BGER",all$V3),1]<- "bger"
all[grep("Znev",all$V3),1]<- "Znev"
all[grep("Mnat",all$V3),1]<- "Mnat"
#all[all$V1==".", 1]<- all$V3[all$V1=="."]
countout<- all %>% group_by(V1,V2,V4) %>% summarise(total.count=n()) %>% as.data.frame %>% unite(V1_V2,V1,V2,sep="_") %>% spread(V1_V2, total.count)
write.table(countout,"mancount.csv",sep="\t",col.names=T)

####
for i in `cat samplename`; do blastp -query "$i"_immpro.pep -db ./Genome_database -max_target_seqs 5 -evalue 1e-5 -num_threads 3 -outfmt "6 qseqid sseqid pident length mismatch gapopen qlen qstart qend qcovhsp slen sstart send evalue bitscore"  -out "$i"_genome.outfmt6; done
