import { describe, it, expect, beforeEach } from 'vitest';

// Mock the Clarity contract environment
const mockClarity = {
  lastItemId: 0,
  items: new Map(),
  
  registerItem(name, description, creationDate, creator, sender) {
    const newId = this.lastItemId + 1;
    this.lastItemId = newId;
    
    this.items.set(newId, {
      name,
      description,
      'creation-date': creationDate,
      creator,
      'registered-by': sender,
      'registration-date': 123 // Mock block height
    });
    
    return { success: true, value: newId };
  },
  
  getItem(itemId) {
    return this.items.get(itemId) || null;
  },
  
  getLastItemId() {
    return this.lastItemId;
  }
};

describe('Item Registration Contract', () => {
  beforeEach(() => {
    mockClarity.lastItemId = 0;
    mockClarity.items = new Map();
  });
  
  it('should register a new item', () => {
    const result = mockClarity.registerItem(
        'Antique Vase',
        'A beautiful 18th century Chinese vase',
        '1750-1780',
        'Unknown',
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
    );
    
    expect(result.success).toBe(true);
    expect(result.value).toBe(1);
    expect(mockClarity.getLastItemId()).toBe(1);
  });
  
  it('should retrieve a registered item', () => {
    mockClarity.registerItem(
        'Antique Chair',
        'Victorian era chair with original upholstery',
        '1880-1890',
        'Thomas Chippendale Workshop',
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'
    );
    
    const item = mockClarity.getItem(1);
    
    expect(item).not.toBeNull();
    expect(item.name).toBe('Antique Chair');
    expect(item.creator).toBe('Thomas Chippendale Workshop');
  });
  
  it('should return null for non-existent items', () => {
    const item = mockClarity.getItem(999);
    expect(item).toBeNull();
  });
});
