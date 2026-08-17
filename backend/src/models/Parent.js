/**
 * Parent Model Schema Definition & Factory
 */
class Parent {
  constructor({
    id,
    name,
    email,
    passwordHash,
    pinHash = null,
    createdAt = new Date().toISOString(),
    updatedAt = new Date().toISOString()
  }) {
    this.id = id;
    this.name = name;
    this.email = email.toLowerCase().trim();
    this.passwordHash = passwordHash;
    this.pinHash = pinHash;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  toJSON() {
    return {
      parentId: this.id,
      id: this.id,
      name: this.name,
      email: this.email,
      role: 'parent',
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    };
  }
}

module.exports = Parent;
