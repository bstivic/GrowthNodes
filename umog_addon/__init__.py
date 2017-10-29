import bpy
from collections import OrderedDict

menus = OrderedDict([
    ("algorithm_menu", {
        "bl_idname": "umog_algorithm_menu",
        "bl_label": "Algorithm Menu",
        "text": "Algorithm",
        "bl_description": "Nodes for systems",
        "icon": "STICKY_UVS_LOC",
        "nodes": [
            #("umog_ReactionDiffusionNode", "Reaction Diffusion Node"),
            ("umog_ReactionDiffusionBGLNode", "Reaction Diffusion Node"),
            ("umog_ConvolveNode", "Convolve"),
            ("umog_ConvolveGLNode", "Convolve opengl"),
        ]
    }),
    (" ", "separator"),
    ("mesh_menu", {
        "bl_idname": "umog_mesh_menu",
        "bl_label": "Mesh Menu",
        "text": "Mesh",
        "bl_description": "Nodes that deal with meshes",
        "icon": "MESH_UVSPHERE",
        "nodes": [
            ("umog_GetMeshNode", "Get Mesh"),
            ("umog_SetMeshNode", "Set Mesh"),
            ("umog_DisplaceNode", "Displace Node"),
        ]
    }),
    ("  ", "separator"),
    ("math_menu", {
        "bl_idname": "umog_math_menu",
        "bl_label": "Math Menu",
        "text": "Math",
        "bl_description": "",
        "icon": "LINENUMBERS_ON",
        "nodes": [
            ("umog_AddNode", "Add"),
            ("umog_SubtractNode", "Subtract"),
            ("umog_MultiplyNode", "Multiply"),
            ("umog_DivideNode", "Divide"),
            ("umog_NegateNode", "Negate"),
            ("umog_NumberNode", "Number"),
        ]
    }),
    ("integer_menu", {
        "bl_idname": "umog_integer_menu",
        "bl_label": "Integer Menu",
        "text": "Integer",
        "bl_description": "Nodes that operate on integers",
        "icon": "LINENUMBERS_ON",
        "nodes": [
            ("umog_IntegerNode", "Integer"),
            ("umog_IntegerFrameNode", "Integer Frame"),
            ("umog_IntegerSubframeNode", "Integer Subframe"),
            ("umog_IntegerMathNode", "Integer Math"),
        ]
    }),
    ("matrix_menu", {
        "bl_idname": "umog_matrix_menu",
        "bl_label": "Matrix Menu",
        "text": "Matrix",
        "bl_description": "Nodes that operate on matrices",
        "icon": "MESH_GRID",
        "nodes": [
            ("umog_Mat3Node", "Matrix 3x3 Node"),
            ("umog_MatrixMathNode", "Matrix Math"),
            ("umog_GaussNode", "Gaussian Blur"),
            ("umog_LaplaceNode", "Laplacian Filter"),
        ]
    }),
    ("  ", "separator"),
    ("texture_menu", {
        "bl_idname": "umog_texture_menu",
        "bl_label": "Texture Menu",
        "text": "Texture",
        "bl_description": "Nodes that operate on Textures",
        "icon": "IMGDISPLAY",
        "nodes": [
            ("umog_GetTextureNode", "Get Texture"),
            ("umog_SetTextureNode", "Set Texture"),
            ("umog_SaveTextureNode", "Save Texture"),
            ("umog_LoadTextureNode", "Load Texture(s)"),
            ("umog_TextureAlternatorNode", "Texture Alternator"),
            
        ]
    })
])

def UMOGCreateMenus():
    for key, value in menus.items():
        if value is not "separator":
            menu = value

            def draw(self, context):
                layout = self.layout
                for node in self.menu["nodes"]:
                    insertNode(layout, node[0], node[1])

            menu_class = type(
                "UMOGMenu%s" % menu["text"],
                (bpy.types.Menu,),
                {
                    "menu": menu,
                    "bl_idname": menu["bl_idname"],
                    "bl_label": menu["bl_label"],
                    "bl_description": menu["bl_description"],
                    "draw": draw
                },
            )
            bpy.utils.register_class(menu_class)


UMOGCreateMenus()

def drawMenu(self, context):
    if context.space_data.tree_type != "umog_UMOGNodeTree": return

    layout = self.layout
    layout.operator_context = "INVOKE_DEFAULT"
    for key, value in menus.items():
        menu = value
        if menu is not "separator":
            layout.menu(menu["bl_idname"], text=menu["text"], icon=menu["icon"])
        else:
            layout.separator()

def insertNode(layout, type, text, settings={}, icon="NONE"):
    operator = layout.operator("node.add_node", text=text, icon=icon)
    operator.type = type
    operator.use_transform = True
    for name, value in settings.items():
        item = operator.settings.add()
        item.name = name
        item.value = value
    return operator


def register():
    bpy.types.NODE_MT_add.append(drawMenu)

def unregister():
    bpy.types.NODE_MT_add.remove(drawMenu)

