#!/usr/bin/env sh
# This file is part of the lpdiff distribution (https://github.com/S-trace/lpdiff).
# Copyright (c) 2022 Soul Trace <S-trace@list.ru>.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

set -e

# Debug flags
# set -x
# set -v

EDITOR="kate"

write_sed_commands() {
	cat <<"EOF" >sed_commands
# move: zap all operands
s/: 01../: 01**/g
# move-result: zap all operands
s/: 0a../: 0a**/g
# move-result-wide: zap all operands
s/: 0b../: 0b**/g
# move-result-object: zap all operands
s/: 0c../: 0c**/g
# return-void: do not filter
s/: 0e00/: 0e00/g
# return: zap all operands
s/: 0f../: 0f**/g
# const/4: zap all operands (need to zap register operand only, but LuckyPatcher can't handle nibbles, only full bytes)
s/: 12../: 12**/g
# const/16: zap register operand
s/: 13../: 13**/g
# const: QUIRK: zap all operands if constant is like resource ID
s/: 14.. .... ..7f/: 14** **** ****/g
# const: zap register operand
s/: 14../: 14**/g
# const/high16: zap register operand
s/: 15../: 15**/g
# const-wide: zap register operand
s/: 18../: 18**/g
# const-wide/high16: zap register operand
s/: 19../: 19**/g
# const-string: zap all operands
s/: 1a.. ..../: 1a** ****/g
# check-cast: zap all operands
s/: 1f.. ..../: 1f** ****/g
# new-instance: zap all operands
s/: 22.. ..../: 22** ****/g
# throw: zap register operand
s/: 27../: 27**/g
# goto: zap offset operand
s/: 28../: 28**/g
# goto/16: zap offset operand
s/: 29.. ..../: 29** ****/g
# packed-switch: zap all operands
s/: 2b.. .... ..../: 2b** **** ****/g
# cmpl-float: zap all operands
s/: 2d.. ..../: 2d** ****/g
# cmpg_float: zap all operands
s/: 2e.. ..../: 2e** ****/g
# cmp-long: zap all operands
s/: 31.. ..../: 31** ****/g
# if-ne: zap all operands
s/: 33.. ..../: 33** ****/g
# if-gt: zap all operands
s/: 36.. ..../: 36** ****/g
# if-eqz: zap all operands
s/: 38.. ..../: 38** ****/g
# if-nez: zap all operands
s/: 39.. ..../: 39** ****/g
# if-gez: zap all operands
s/: 3b.. ..../: 3b** ****/g
# if-gtz: zap all operands
s/: 3c.. ..../: 3c** ****/g
# iget: zap all operands
s/: 52.. ..../: 52** ****/g
# iget-object: zap all operands
s/: 54.. ..../: 54** ****/g
# iput: zap all operands
s/: 59.. ..../: 59** ****/g
# sget: zap all operands
s/: 60.. ..../: 60** ****/g
# sget-wide: zap all operands
s/: 61.. ..../: 61** ****/g
# sget-boolean: zap all operands
s/: 63.. ..../: 63** ****/g
# sput: zap all operands
s/: 67.. ..../: 67** ****/g
# invoke-virtual: zap all operands
s/: 6e.. .... ..../: 6e** **** ****/g
# invoke-direct: zap all operands
s/: 70.. .... ..../: 70** **** ****/g
# invoke-static: zap all operands
s/: 71.. .... ..../: 71** **** ****/g
# invoke-interface: zap all operands
s/: 72.. .... ..../: 72** **** ****/g
# int-to-long: zap all operands
s/: 81../: 81**/g
# long-to-float: zap all operands
s/: 85../: 85**/g
# float-to-double: zap all operands
s/: 89../: 89**/g
# add-int/2addr: zap all operands
s/: b0../: b0**/g
# mul-long/2addr: zap all operands
s/: bb../: bb**/g
# sub-long/2addr: zap all operands
s/: bc../: bc**/g
# mul-long/2addr: zap all operands
s/: bd../: bd**/g
# div-float/2addr: zap all operands
s/: c9../: c9**/g
# add-double/2addr: zap all operands
s/: cb../: cb**/g
# sub-double/2addr: zap all operands
s/: cc../: cc**/g
# mul-double/2addr: zap all operands
s/: cd../: cd**/g
EOF
}

assembly_smali() {
	ORIGIN=$1
	RESULT=$2
	echo "INFO: Assembling ${ORIGIN} to ${RESULT}"
	smali assemble "${ORIGIN}" --output "${RESULT}"
}

dump_dex() {
	ORIGIN=$1
	RESULT=$2
	echo "INFO: Dumping assembled smali ${ORIGIN} to ${RESULT}"
	baksmali dump "${ORIGIN}" >"${RESULT}"
	rm "${ORIGIN}"
}

check_size_match() {
	FILE1=$1
	FILE2=$2
	FILE1_SIZE=$(wc -c <"${FILE1}")
	FILE2_SIZE=$(wc -c <"${FILE2}")
	if [ "${FILE1_SIZE}" -ne "${FILE2_SIZE}" ]; then
		echo "ERROR: \"${FILE1}\" size and \"${FILE2}\" size mismatch! Check sed_commands! This mostly means that generated patches won't apply! Exiting!"
		exit 1
	fi
}

filter_opcodes() {
	ORIGIN=$1
	RESULT=$2
	echo "INFO: Filtering opcodes"
	write_sed_commands
	sed --file sed_commands "${ORIGIN}" >"${RESULT}"
	check_size_match "${ORIGIN}" "${RESULT}"
	rm sed_commands "${ORIGIN}"
}

diff_changes() {
	ORIGIN=$1
	RESULT=$2
	DIFF=$3
	echo "INFO: Diffing changes"
	# true: Ignore error
	diff -u50 "${ORIGIN}" "${RESULT}" >"${DIFF}" || true
}

wait_for_edit() {
	ORIGIN=$1
	RESULT=$2
	DIFF=$3
	echo "INFO: Please edit origin and result files to keep only desired code region according to diff file (it will go to LuckyPatcher patch lines)"
	echo "INFO: If not all opcodes were filtered properly - please edit write_sed_commands procedure in $0"
	"${EDITOR}" "${ORIGIN}" "${RESULT}" "${DIFF}"
	echo "INFO: Press ENTER to continue when ready (don't forget to save files before!)"
	# shellcheck disable=SC2034
	read -r delay # Waiting for user
}

filter_luckypatcher_bytes_file() {
	FILE=$1
	grep -oP ': \K[^|]+' "${FILE}" | tr -d ' ' | sed 's/\([0-9a-f*]\{2\}[\t ]\{0,\}\)/\1 /g' | tr -d '\n'
}

filter_luckypatcher_bytes() {
	ORIGIN=$1
	RESULT=$2
	OUTPUT=$3
	echo "INFO: Filter only bytes for LuckyPatcher patch lines from dump"
	ORIGIN_FILTERED=$(filter_luckypatcher_bytes_file "${ORIGIN}")
	RESULT_FILTERED=$(filter_luckypatcher_bytes_file "${RESULT}")
	printf '{"original":"%s"}\n' "${ORIGIN_FILTERED}" >"${OUTPUT}"
	printf '{"replaced":"%s"}\n' "${RESULT_FILTERED}" >>"${OUTPUT}"
	rm "${ORIGIN}" "${RESULT}"
	echo "INFO: Done, results are in ${OUTPUT}"
}

main() {
	SRC=$(basename "$1" .smali)
	DST=$(basename "$2" .smali)
	echo "INFO: Processing lpdiff ${SRC} vs ${DST}"
	assembly_smali "${SRC}.smali" "${SRC}.dex"
	assembly_smali "${DST}.smali" "${DST}.dex"
	dump_dex "${SRC}.dex" "${SRC}.dump"
	dump_dex "${DST}.dex" "${DST}.dump"

	filter_opcodes "${SRC}.dump" "${SRC}_filtered.dump"
	filter_opcodes "${DST}.dump" "${DST}_filtered.dump"

	diff_changes "${SRC}_filtered.dump" "${DST}_filtered.dump" "${SRC}-${DST}.diff"

	wait_for_edit "${SRC}_filtered.dump" "${DST}_filtered.dump" "${SRC}-${DST}.diff"

	filter_luckypatcher_bytes "${SRC}_filtered.dump" "${DST}_filtered.dump" "${SRC}-${DST}.lp"

	"${EDITOR}" "${SRC}-${DST}.lp"
}

main "$1" "$2"
