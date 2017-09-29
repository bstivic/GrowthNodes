import bpy
import sys
from bpy.props import *
from .. base_types import UMOGSocket
from .. utils.events import propUpdate


def getValue(self):
    return min(max(self.minValue, self.get("value", 0)), self.maxValue)
def setValue(self, value):
    self["value"] = min(max(self.minValue, value), self.maxValue)

class FloatSocket(bpy.types.NodeSocket, UMOGSocket):
    # Description string
    '''Custom Float socket type'''
    # Optional identifier string. If not explicitly defined, the python class name is used.
    bl_idname = 'FloatSocketType'
    # Label for nice name display
    bl_label = 'Float Socket'
    dataType = "Float"
    allowedInputTypes = ["Float", "Integer", "Boolean"]

    useIsUsedProperty = False
    defaultDrawType = "TEXT_PROPERTY"

    drawColor = (1, 0, 1, 0.5)

    comparable = True
    storable = True

    value = FloatProperty(default = 0.0,
        set = setValue, get = getValue,
        update = propUpdate)

    minValue = FloatProperty(default = -1e10)
    maxValue = FloatProperty(default = sys.float_info.max)

    def drawProperty(self, context, layout, text, node):
        layout.prop(self, "value", text = text)

    def getValue(self):
        return self.value

    def setProperty(self, data):
        self.value = data

    def getProperty(self):
        return self.value

    def refresh(self):
        print("refresh from socket", self.name, self.node)