# About lpdiff

lpdiff - a tool for creating LuckyPatcher patch lines from original and patched .smali files.

It is intended to automatize the creation of LuckyPatcher custom patch pattern lines which may survive small changes in app code.

# Usage

## Create files

1. Save original .smali as **origin.smali**
2. Patch .smali.
3. Save patched .smali as **result.smali**

File names may be arbitrary, but must have **.smali** at their ends


## Start lpdiff

Change **EDITOR** variable to your favorite editor and start the script:

`./lpdiff.sh origin.smali result.smali`

## Edit dump files

lpdiff will open editor for **origin_filtered.dump**,  **result_filtered.dump** and **origin-result.diff** files.

**origin-result.diff**  is for reference only, look there to see changes.

Edit **origin_filtered.dump** and **result_filtered.dump**  to keep only changes for single patch pattern:

1. Find line `code_item: Lpatched/class;->patchedMethod()V`
2. Find the `instructions:` line below it.
3. Remove all lines above this line (including the `instructions:` line).
4. This is the start of the method code.
5. Find the end of the method code (usually return, return-void or return-object) and remove all lines below.
6. Verify that all HEX instructions were properly filtered (operands that may change between app builds should be masked by ** symbols). Generally, the second byte of almost all opcodes should be masked
7. Save dump files and close the editor.
8. Press ENTER in lpdiff's terminal to continue.
9. lpdiff will open `EDITOR` with the resulting LuckyPatcher custom patch pattern

# Adding opcode masking data

You should edit the `write_sed_commands` function in **lpdiff.sh** if you need to mask opcodes that are not yet added to lpdiff.

The opcodes masking list currently is not comprehensive and will be updated during **lpdiff** usage in real life - feel free to submit pull requests here.

