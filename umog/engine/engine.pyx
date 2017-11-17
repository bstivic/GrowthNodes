import numpy as np
cimport numpy as np

import bpy

import cython
cimport cython
from cpython.ref cimport PyObject
from libc.stdlib cimport malloc, free
from libc.stdint cimport uintptr_t

from libc.math cimport fmod

import types
cimport types
from mesh cimport *

from collections import namedtuple
from enum import Enum

# operation

Operation = namedtuple('Operation', ['opcode', 'input_types', 'output_types', 'buffer_types', 'arguments', 'parameters'])
class ArgumentType(Enum):
    SOCKET = 0
    BUFFER = 1
Argument = namedtuple('Argument', ['type', 'index'])

# data

cdef class ArrayData:
    def __init__(self):
        self.tag = ARRAY

cdef class MeshData:
    def __init__(self):
        self.tag = MESH

# engine

cdef class Engine:
    cdef list buffers
    cdef list instructions
    cdef list outputs

    def __init__(self, list nodes):
        self.instructions = []
        self.buffers = []
        self.outputs = []

        buffer_types = []

        index = 0
        indices = {}

        cdef object output_type
        cdef ArrayData array_data
        cdef MeshData mesh_data
        for (node_i, (node, inputs)) in enumerate(nodes):
            input_types = [buffer_types[indices[input]] for input in inputs]
            operation = node.get_operation(input_types)
            buffer_values = node.get_buffer_values()

            instruction = Instruction()
            instruction.op = operation.opcode
            for (i, parameter) in enumerate(operation.parameters):
                instruction.parameters[i] = parameter

            # create internal buffers
            buffer_indices = []
            for (buffer_i, buffer_value) in enumerate(buffer_values):
                self.buffers.append(create_buffer(operation.buffer_types[buffer_i], buffer_value))
                buffer_types.append(operation.buffer_types[buffer_i])
                buffer_indices.append(index)
                index += 1

            # set instruction argument indices
            for (argument_i, argument) in enumerate(operation.arguments):
                if argument.type == ArgumentType.BUFFER:
                    instruction.ins[argument_i] = buffer_indices[argument.index]
                elif argument.type == ArgumentType.SOCKET:
                    instruction.ins[argument_i] = indices[inputs[argument.index]]

            # create output buffers
            if instruction.op == CONST:
                indices[(node_i, 0)] = buffer_indices[0]
            elif instruction.op != NOP:
                for (output_i, output_type) in enumerate(operation.output_types):
                    indices[(node_i, output_i)] = index
                    instruction.outs[output_i] = index
                    self.buffers.append(create_buffer(output_type))
                    buffer_types.append(output_type)
                    index += 1

                self.instructions.append(instruction)

            if node._IsOutputNode:
                self.outputs.append((node, instruction.ins[0]))

    def run(self):
        self.debug()

        cdef Instruction instruction
        for instruction in self.instructions:
            if instruction.op == ADD:
                add(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == SUBTRACT:
                sub(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == MULTIPLY:
                mul(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == DIVIDE:
                div(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == NEGATE:
                neg(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]])
            elif instruction.op == POWER:
                pow(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == MODULUS:
                mod(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])

            elif instruction.op == EQ:
                eq(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == NEQ:
                neq(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == LT:
                lt(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == GT:
                gt(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == LEQ:
                leq(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == GEQ:
                geq(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])

            elif instruction.op == NOT:
                boolean_not(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]])
            elif instruction.op == AND:
                boolean_and(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == OR:
                boolean_or(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])
            elif instruction.op == XOR:
                boolean_xor(<ArrayData>self.buffers[instruction.outs[0]], <ArrayData>self.buffers[instruction.ins[0]], <ArrayData>self.buffers[instruction.ins[1]])

            elif instruction.op == DISPLACE:
                # don't copy if we're mutating in place
                if instruction.outs[0] != instruction.ins[0]:
                    (<MeshData>self.buffers[instruction.outs[0]]).mesh = copy_mesh((<MeshData>self.buffers[instruction.ins[0]]).mesh)
                displace((<MeshData>self.buffers[instruction.outs[0]]).mesh, (<ArrayData>self.buffers[instruction.ins[1]]).array)
            elif instruction.op == LOOP:
                pass
            elif instruction.op == CONST:
                pass
            elif instruction.op == NOP:
                pass

        # output values
        for (output_node, buffer_i) in self.outputs:
            if (<Data>self.buffers[buffer_i]).tag == ARRAY:
                output_node.output_value((<ArrayData>self.buffers[buffer_i]).array)
            elif (<Data>self.buffers[buffer_i]).tag == MESH:
                output_node.output_value((<MeshData>self.buffers[buffer_i]).mesh)

    def debug(self):
        print('instructions:')
        cdef Instruction instruction
        cdef int i
        for (i, instruction) in enumerate(self.instructions):
            print(str(i) + '. ' + str((instruction.op, instruction.ins, instruction.outs)))

        print('buffers:')
        cdef Data data
        for (i,data) in enumerate(self.buffers):
            print(str(i) + '. ' + str(data.tag))

def create_buffer(buffer_type, value=None):
    cdef ArrayData array_data
    cdef MeshData mesh_data
    cdef BlenderMesh *blender_mesh
    if buffer_type.tag == types.SCALAR:
        array_data = ArrayData()
        array_data.array = np.ndarray(shape=(1,1,1,1,1), dtype=np.float32)
        if value is not None:
            array_data.array[0,0,0,0,0] = value
        return array_data
    elif buffer_type.tag == types.VECTOR:
        array_data = ArrayData()
        array_data.array = np.ndarray(shape=(buffer_type.channels,1,1,1,1), dtype=np.float32)
        if value is not None:
            array_data.array[:,0,0,0,0] = value
        return array_data
    elif buffer_type.tag == types.ARRAY:
        array_data = ArrayData()
        array_data.array = np.ndarray(shape=(
            buffer_type.channels,
            buffer_type.x_size,
            buffer_type.y_size,
            buffer_type.z_size,
            buffer_type.t_size), dtype=np.float32)
        if value is not None:
            array_data.array = value
        return array_data
    elif buffer_type.tag == types.FUNCTION:
        pass
    elif buffer_type.tag == types.MESH:
        mesh_data = MeshData()
        if value is not None:
            blender_mesh = <BlenderMesh *><uintptr_t>value.as_pointer()
            mesh_data.mesh = Mesh(blender_mesh.totvert, blender_mesh.totloop, blender_mesh.totpoly)
            from_blender_mesh(mesh_data.mesh, blender_mesh)
        return mesh_data

cpdef float[:,:,:,:,:] sequence(int start, int end):
    cdef int i
    cdef float[:,:,:,:,:] result = np.ndarray(shape=(1,1,1,1,end-start), dtype=np.float32)
    for i in range(start, end):
        result[0,0,0,0,i] = <float>i
    return result
