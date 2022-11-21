# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Common helper utilities and constants for fhe bazel files."""

_TFHE_CELLS_LIBERTY = "//transpiler:tfhe_cells.liberty"
_OPENFHE_CELLS_LIBERTY = "//transpiler:openfhe_cells.liberty"

FHE_ENCRYPTION_SCHEMES = {
    "cleartext": _TFHE_CELLS_LIBERTY,
    "openfhe": _OPENFHE_CELLS_LIBERTY,
    "tfhe": _TFHE_CELLS_LIBERTY,
    "tfhe_jax": _TFHE_CELLS_LIBERTY,
}

BooleanifiedIrOutputInfo = provider(
    """The output of booleanifying XLS IR emitted by XLScc.""",
    fields = {
        "ir": "XLS IR file generated by XLScc compiler",
        "metadata": "XLS IR protobuf by XLScc compiler",
        "generic_struct_header": "Templates for generic encodings of C++ structs in the source headers. May be None",
        "hdrs": "Input C++ headers",
    },
)

BooleanifiedIrInfo = provider(
    """Non-file attributes passed forward from XlsCcOutputInfo.""",
    fields = {
        "library_name": "Library name; if empty, stem is used to derive names.",
        "stem": "Name stem derived from input source C++ file (e.g., 'myfile' from 'myfile.cc'.)",
        "optimizer": "Optimizer used to generate the IR",
    },
)

VerilogOutputInfo = provider(
    """Files generated by the conversion of XLS IR to Verilog, as well as file
       attributes passed along from other providers.""",
    fields = {
        "verilog_ir_file": "Optimizer used to generate the IR",
        "metadata": "XLS IR protobuf by XLScc compiler",
        "metadata_entry": "Text file containing the entry point for the program",
        "generic_struct_header": "Templates for generic encodings of C++ structs in the source headers",
        "hdrs": "Input C++ headers",
    },
)

VerilogInfo = provider(
    """Non-file attributes passed along from other providers.""",
    fields = {
        "library_name": "Library name; if empty, stem is used to derive names.",
        "stem": "Name stem derived from input source C++ file (e.g., 'myfile' from 'myfile.cc'.)",
    },
)

def executable_attr(label):
    """A helper for declaring internal executable dependencies."""
    return attr.label(
        default = Label(label),
        allow_single_file = True,
        executable = True,
        cfg = "exec",
    )

def run_with_stem(ctx, stem, inputs, out_ext, tool, args, entry = None):
    """A helper to run a shell script and capture the output.

    Args:
      ctx:  The blaze context.
      stem: Stem for the output file.
      inputs: A list of files used by the shell.
      out_ext: An extension to add to the current label for the output file.
      tool: What tool to run.
      args: A list of arguments to pass to the tool.
      entry: If specified, it points to a file containing the entry point; that
             information is extracted and provided as value to the --top
             command-line switch.

    Returns:
      The File output.
    """
    out = ctx.actions.declare_file("%s%s" % (stem, out_ext))
    arguments = " ".join(args)
    if entry != None:
        arguments += " --top $(cat {})".format(entry.path)
    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [out],
        tools = [tool],
        command = "%s %s > %s" % (tool.path, arguments, out.path),
    )
    return out