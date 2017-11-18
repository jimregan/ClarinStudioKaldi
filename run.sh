#!/bin/bash

. ./path.sh ## set the paths in this file correctly!

# link to scripts from the standard Kaldi distribution
# we try to use these as much as possible
#if [ ! -f $KALDI_ROOT/egs/wsj/s5/conf ] ; then ln -s $KALDI_ROOT/egs/wsj/s5/conf ; fi
#if [ ! -f $KALDI_ROOT/egs/wsj/s5/local ] ; then ln -s $KALDI_ROOT/egs/wsj/s5/local ; fi
#if [ ! -f $KALDI_ROOT/egs/wsj/s5/utils ] ; then ln -s $KALDI_ROOT/egs/wsj/s5/utils ; fi
#if [ ! -f $KALDI_ROOT/egs/wsj/s5/steps ] ; then ln -s $KALDI_ROOT/egs/wsj/s5/steps ; fi

# exits script if error occurs anywhere
# you might not want to do this for interactive shells.
set -eu

# check if the user wants to clean the project
#local_clarin/clarin_pl_clean.sh

export nj=40 ##number of concurrent processes

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.

#run some initial data preparation (look at the file for more details):
#local_clarin/clarin_pl_data_prep.sh

#prepare the lang directory
#utils/prepare_lang.sh data/local/dict_nosp "<unk>" data/local/tmp_nosp data/lang_nosp

#make G.fst
#utils/format_lm.sh data/lang_nosp local_clarin/arpa.lm.gz data/local/dict_nosp/lexicon.txt data/lang_nosp_test

# Make normalized MFCC features.
#steps/make_mfcc.sh --nj $nj data/train
#steps/compute_cmvn_stats.sh data/train
#steps/make_mfcc.sh --nj $nj data/test
#steps/compute_cmvn_stats.sh data/test

#train Monophone system
#steps/train_mono.sh --nj $nj data/train data/lang_nosp exp/mono0

#test Monophone system
#utils/mkgraph.sh --mono data/lang_nosp_test exp/mono0 exp/mono0/graph
#steps/decode.sh --nj $nj exp/mono0/graph data/test exp/mono0/decode

#align using the Monophone system
#steps/align_si.sh --nj $nj data/train data/lang_nosp exp/mono0 exp/mono0_ali

#train initial Triphone system
#steps/train_deltas.sh 2000 10000 data/train data/lang_nosp exp/mono0_ali exp/tri1

#test initial Triphone system
#utils/mkgraph.sh data/lang_nosp_test exp/tri1 exp/tri1/graph
#steps/decode.sh --nj $nj exp/tri1/graph data/test exp/tri1/decode

#re-align using the initial Triphone system
#steps/align_si.sh --nj $nj data/train data/lang_nosp exp/tri1 exp/tri1_ali

#train tri2a, which is deltas + delta-deltas
#steps/train_deltas.sh 2500 15000 data/train data/lang_nosp exp/tri1_ali exp/tri2a

#test tri2a
#utils/mkgraph.sh data/lang_nosp_test exp/tri2a exp/tri2a/graph
#steps/decode.sh --nj $nj exp/tri2a/graph data/test exp/tri2a/decode

#train tri2b, which is tri2a + LDA
#steps/train_lda_mllt.sh --splice-opts "--left-context=3 --right-context=3" \
#   2500 15000 data/train data/lang_nosp exp/tri1_ali exp/tri2b

#test tri2b
#utils/mkgraph.sh data/lang_nosp_test exp/tri2b exp/tri2b/graph
#steps/decode.sh --nj $nj exp/tri2b/graph data/test exp/tri2b/decode

#re-align tri2b system
#steps/align_si.sh --nj $nj --use-graphs true data/train data/lang_nosp exp/tri2b exp/tri2b_ali 


#from 2b system, train 3b which is LDA + MLLT + SAT.
#steps/train_sat.sh 2500 15000 data/train data/lang_nosp exp/tri2b_ali exp/tri3b

#test tri3b
#utils/mkgraph.sh data/lang_nosp_test exp/tri3b exp/tri3b/graph_nosp
#steps/decode_fmllr.sh --nj $nj exp/tri3b/graph_nosp data/test exp/tri3b/decode_nosp

#get pronounciation probabilities and silence information 
#./steps/get_prons.sh data/train data/lang_nosp exp/tri3b || exit  1;

#recreate dict with new pronounciation and silence probabilities
#./utils/dict_dir_add_pronprobs.sh data/local/dict_nosp \
#	exp/tri3b/pron_counts_nowb.txt \
#	exp/tri3b/sil_counts_nowb.txt \
#	exp/tri3b/pron_bigram_counts_nowb.txt data/local/dict

#recreate lang directory
#utils/prepare_lang.sh data/local/dict "<unk>" data/local/tmp data/lang

#recreate G.fst
#utils/format_lm.sh data/lang local_clarin/arpa.lm.gz data/local/dict/lexicon.txt data/lang_test

#test tri3b again
#utils/mkgraph.sh data/lang_test exp/tri3b exp/tri3b/graph
#steps/decode_fmllr.sh --nj $nj exp/tri3b/graph data/test exp/tri3b/decode

#from 3b system, align all data
#steps/align_fmllr.sh --nj $nj data/train data/lang exp/tri3b exp/tri3b_ali

#train MMI on tri3b (LDA+MLLT+SAT)
#steps/make_denlats.sh --nj $nj --transform-dir exp/tri3b_ali data/train data/lang \
#	exp/tri3b exp/tri3b_denlats
#steps/train_mmi.sh data/train data/lang exp/tri3b_ali exp/tri3b_denlats exp/tri3b_mmi

#test MMI
#steps/decode_fmllr.sh --nj $nj --alignment-model exp/tri3b/final.alimdl --adapt-model exp/tri3b/final.mdl \
#  exp/tri3b/graph data/test exp/tri3b_mmi/decode

#decode MMI using wider beam
#steps/decode_fmllr.sh --nj $nj --alignment-model exp/tri3b/final.alimdl --adapt-model exp/tri3b/final.mdl \
#  --beam 24 --lattice-beam 12 \
#  exp/tri3b/graph data/test exp/tri3b_mmi/decode_wb

#compute the oracle on the last decoding result - to see how much is possible using these lattices
#./steps/oracle_wer.sh data/test data/lang exp/tri3b_mmi/decode_wb

#download a large LM (~843MB)
#if [ ! -f local_clarin/large.arpa.gz ] ; then
#(
#	cd local_clarin
#	curl -O http://mowa.clarin-pl.eu/korpusy/large.arpa.gz
#)
#fi

#create the const-arpa lang dir
#./utils/build_const_arpa_lm.sh local_clarin/large.arpa.gz data/lang data/lang_carpa

#perform rescoring using the large LM in carpa format (much faster than regular arpa)
#./steps/lmrescore_const_arpa.sh data/lang_test data/lang_carpa data/test exp/tri3b_mmi/decode_wb exp/tri3b_mmi/decode_rs

# NNET setups - run the ones below only if you have a fast computer with GPUs!

# Commmon for all of the below:
#./local/nnet3/run_ivector_common.sh --nj $nj --train_set train --test_sets test --gmm tri3b_ali
#./local/nnet3/run_ivector_common.sh --stage 3 --nj $nj --train_set train --test_sets test --gmm tri3b_ali

#./local_clarin/clarin_tdnn.sh --gmm tri3b_ali --stage 10
#steps/nnet3/decode.sh --nj $nj --num-threads 4 --online-ivector-dir exp/nnet3/ivectors_test_hires \
#          exp/tri3b/graph data/test_hires exp/nnet3/tdnn1a_sp/decode
#./steps/oracle_wer.sh data/test_hires data/lang exp/nnet3/tdnn1a_sp/decode
#./steps/lmrescore_const_arpa.sh data/lang_test data/lang_carpa data/test_hires exp/nnet3/tdnn1a_sp/decode exp/nnet3/tdnn1a_sp/decode_rs

# Same as above but using the chain framework - trains about the same, works much faster as has lower WER
#./local_clarin/clarin_chain_tdnn.sh --stage 10
./local_clarin/clarin_chain_tdnn.sh --stage 16
./steps/oracle_wer.sh data/test_hires data/lang exp/chain/tdnn1f_sp/decode
./steps/lmrescore_const_arpa.sh data/lang_test data/lang_carpa data/test_hires exp/chain/tdnn1f_sp/decode exp/chain/tdnn1f_sp/decode_rs

# Getting results
find exp -name best_wer | while read f ; do cat $f ; done | sort -k2nr
find exp -name oracle_wer | while read f ; do echo -n "$f: " ; cat $f ; done | sort -k2nr
