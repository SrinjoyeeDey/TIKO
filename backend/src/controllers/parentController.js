const Parent = require('../models/Parent');
const Child = require('../models/Child');
const crypto = require('crypto');

// In-memory persistent collections for development/prototype API
const parentsStore = new Map();
const childrenStore = new Map();

// Helper to hash password/PIN with SHA-256
function hashSecret(secret) {
  if (!secret) return null;
  return crypto.createHash('sha256').update(secret.toString().trim()).digest('hex');
}

class ParentController {
  // Signup Parent Account
  async signup(req, res) {
    try {
      const { name, email, password } = req.body;

      if (!name || !email || !password) {
        return res.status(400).json({ error: 'Name, email, and password are required' });
      }

      const normalizedEmail = email.toLowerCase().trim();
      
      // Check existing email
      for (const p of parentsStore.values()) {
        if (p.email === normalizedEmail) {
          return res.status(409).json({ error: 'An account with this email already exists' });
        }
      }

      const parentId = `parent_${crypto.randomBytes(6).toString('hex')}`;
      const passwordHash = hashSecret(password);

      const parent = new Parent({
        id: parentId,
        name: name.trim(),
        email: normalizedEmail,
        passwordHash,
      });

      parentsStore.set(parentId, parent);

      return res.status(201).json({
        success: true,
        parent: parent.toJSON(),
      });
    } catch (err) {
      console.error('Signup error:', err);
      return res.status(500).json({ error: 'Internal server error during signup' });
    }
  }

  // Create or update Parent PIN
  async setPin(req, res) {
    try {
      const { parentId, pin } = req.body;

      if (!parentId || !pin) {
        return res.status(400).json({ error: 'parentId and pin are required' });
      }

      const parent = parentsStore.get(parentId);
      if (!parent) {
        return res.status(404).json({ error: 'Parent account not found' });
      }

      parent.pinHash = hashSecret(pin);
      parent.updatedAt = new Date().toISOString();

      return res.status(200).json({
        success: true,
        message: 'Parent PIN set successfully',
        parent: parent.toJSON(),
      });
    } catch (err) {
      console.error('Set PIN error:', err);
      return res.status(500).json({ error: 'Internal server error setting PIN' });
    }
  }

  // Verify Parent PIN
  async verifyPin(req, res) {
    try {
      const { parentId, pin } = req.body;

      if (!pin) {
        return res.status(400).json({ error: 'PIN is required' });
      }

      const targetPinHash = hashSecret(pin);

      let foundParent = null;
      if (parentId) {
        foundParent = parentsStore.get(parentId);
      } else {
        // Return first matching parent with this PIN if parentId omitted
        for (const p of parentsStore.values()) {
          if (p.pinHash === targetPinHash) {
            foundParent = p;
            break;
          }
        }
      }

      if (!foundParent || foundParent.pinHash !== targetPinHash) {
        // Standard non-revealing response
        return res.status(401).json({ success: false, error: 'Incorrect PIN. Try again.' });
      }

      return res.status(200).json({
        success: true,
        parent: foundParent.toJSON(),
      });
    } catch (err) {
      console.error('Verify PIN error:', err);
      return res.status(500).json({ error: 'Internal server error verifying PIN' });
    }
  }

  // Get children linked to parent
  async getChildren(req, res) {
    try {
      const { parentId } = req.params;
      const results = [];

      for (const child of childrenStore.values()) {
        if (child.parentId === parentId) {
          results.push(child);
        }
      }

      return res.status(200).json({ children: results });
    } catch (err) {
      return res.status(500).json({ error: 'Failed to fetch children profiles' });
    }
  }

  // Create child profile under parent
  async createChild(req, res) {
    try {
      const { parentId } = req.params;
      const { name, age, preferences } = req.body;

      if (!name) {
        return res.status(400).json({ error: 'Child name is required' });
      }

      const childId = `child_${crypto.randomBytes(6).toString('hex')}`;
      const newChild = {
        id: childId,
        childId,
        parentId,
        name: name.trim(),
        age: age ? parseInt(age) : 6,
        preferences: preferences || {},
        createdAt: new Date().toISOString(),
      };

      childrenStore.set(childId, newChild);

      return res.status(201).json({
        success: true,
        child: newChild,
      });
    } catch (err) {
      return res.status(500).json({ error: 'Failed to create child profile' });
    }
  }
}

module.exports = new ParentController();
