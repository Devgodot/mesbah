from marshmallow import fields, Schema


class UserSchema(Schema):
    id = fields.String()
    username = fields.String()
    phone = fields.String()
    data = fields.Dict()
class GroupSchema(Schema):
    id = fields.Integer()
    position = fields.Integer()
    name = fields.String()
    icon = fields.String()
    score = fields.Integer()
    diamonds = fields.Integer()
class BookSchema(Schema):
    id = fields.String()
    link = fields.String()
    name = fields.String()
    writer = fields.String()
    description = fields.String()
    img_refrence = fields.String()
    