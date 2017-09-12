#!/bin/sh

function usage()
{
  cat <<EOF

A sample script to obtain pre-mRNA sequences from the UCSC Table Browser

usage:
  $0 [-t TRACK (default: knownGene)] [-d DB (default: hg19)] [-o ORG (default: Human)] [-h HUB_URL] [-b BROWSER_URL (default: http://genome-asia.ucsc.edu)]

requirements:
* sed
* curl
* xmllint


EOF
  exit 1;
}

### default setting
browser=http://genome-asia.ucsc.edu/
org=Human
db=hg19
track=knownGene
hubUrl=http://fantom.gsc.riken.jp/5/datahub/hub.txt
#track=FANTOM_CAT_lv4_stringent

### handle options
while getopts b:o:d:t:h: opt
do
  case ${opt} in
  b) browser=${OPTARG};;
  o) org=${OPTARG};;
  d) db=${OPTARG};;
  t) track=${OPTARG};;
  h) hubUrl=${OPTARG};;
  *) usage;;
  esac
done


### get hgsid
str="${browser}/cgi-bin/hgTables?clade=mammal&org=${org}&db=${db}&hgta_group=allTracks&hubUrl=${hubUrl}"
hgsid=$(
  curl -sS $str \
  | xmllint --html --xpath "//input[@name='hgsid']/@value" - 2> /dev/null \
  | cut -f 2 -d '"'
)

### get track id
str="${browser}/cgi-bin/hgTables?hgsid=${hgsid}"
trackId=$(
  curl -sS $str \
  | xmllint  --html --xpath "//select[@name='hgta_track']/option" - 2> /dev/null \
  | sed -e "s/.*value=\"\(.*${track}.*\)/\1/" \
  | cut -f 1 -d '"'
)

### set the track as target
hgsid=$(
  curl -sS "${browser}/cgi-bin/hgTables?hgsid=${hgsid}&hgta_track=${trackId}" \
  | xmllint --html --xpath "//input[@name='hgsid']/@value" - 2> /dev/null \
  | cut -f 2 -d '"'
)

### get exon and intron sequences
str="${browser}/cgi-bin/hgTables?hgsid=${hgsid}"
str=${str}"&hgSeq.promoterSize=0&boolshad.hgSeq.promoter=0"
str=${str}"&hgSeq.utrExon5=on&boolshad.hgSeq.utrExon5=0"
str=${str}"&hgSeq.cdsExon=on&boolshad.hgSeq.cdsExon=0"
str=${str}"&hgSeq.utrExon3=on&boolshad.hgSeq.utrExon3=0"
str=${str}"&hgSeq.intron=on&boolshad.hgSeq.intron=0"
str=${str}"&boolshad.hgSeq.downstream=0&hgSeq.downstreamSize=0"
str=${str}"&hgSeq.granularity=gene"
str=${str}"&hgSeq.padding5=0&hgSeq.padding3=0"
str=${str}"&boolshad.hgSeq.splitCDSUTR=0"
str=${str}"&hgSeq.casing=exon&boolshad.hgSeq.maskRepeats=0"
str=${str}"&hgSeq.repMasking=lower"
str=${str}"&hgta_doGenomicDna=get+sequence"
curl -sS $str


