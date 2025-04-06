import { describe, it, expect, beforeEach } from 'vitest';

// Mock the Clarity contract environment
const mockClarity = {
  admin: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM',
  approvedRestorers: new Map(),
  restorations: new Map(),
  restorationCounts: new Map(),
  
  registerRestorer(restorerAddress, name, credentials, sender) {
    if (sender !== this.admin) {
      return { success: false, error: 403 };
    }
    
    this.approvedRestorers.set(restorerAddress, {
      name,
      credentials,
      active: true
    });
    
    return { success: true };
  },
  
  recordRestoration(itemId, description, dateStarted, dateCompleted, techniquesUsed, materialsUsed, sender) {
    const restorer = this.approvedRestorers.get(sender);
    
    if (!restorer || !restorer.active) {
      return { success: false, error: 401 };
    }
    
    const countData = this.restorationCounts.get(itemId) || { count: 0 };
    const currentCount = countData.count;
    const newCount = currentCount + 1;
    
    // Record the restoration
    const key = `${itemId}-${newCount}`;
    this.restorations.set(key, {
      restorer: sender,
      description,
      'date-started': dateStarted,
      'date-completed': dateCompleted,
      'techniques-used': techniquesUsed,
      'materials-used': materialsUsed
    });
    
    // Update count
    this.restorationCounts.set(itemId, { count: newCount });
    
    return { success: true, value: newCount };
  },
  
  getRestoration(itemId, restorationId) {
    const key = `${itemId}-${restorationId}`;
    return this.restorations.get(key) || null;
  },
  
  getRestorationCount(itemId) {
    return this.restorationCounts.get(itemId) || { count: 0 };
  },
  
  isApprovedRestorer(address) {
    return this.approvedRestorers.has(address);
  }
};

describe('Restoration Tracking Contract', () => {
  beforeEach(() => {
    mockClarity.approvedRestorers = new Map();
    mockClarity.restorations = new Map();
    mockClarity.restorationCounts = new Map();
  });
  
  it('should register a new restorer', () => {
    const result = mockClarity.registerRestorer(
        'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG',
        'Jane Smith',
        'Master of Conservation, 15 years experience',
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM' // Admin
    );
    
    expect(result.success).toBe(true);
    expect(mockClarity.isApprovedRestorer('ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG')).toBe(true);
  });
  
  it('should not allow non-admins to register restorers', () => {
    const result = mockClarity.registerRestorer(
        'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG',
        'Jane Smith',
        'Master of Conservation',
        'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5YC7WZ5EN' // Not admin
    );
    
    expect(result.success).toBe(false);
    expect(result.error).toBe(403);
  });
  
  it('should allow approved restorers to record restorations', () => {
    // Register restorer first
    mockClarity.registerRestorer(
        'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG',
        'Jane Smith',
        'Master of Conservation',
        'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM' // Admin
    );
    
    const result = mockClarity.recordRestoration(
        1, // Item ID
        'Repaired crack in base and restored missing glaze',
        1620000000, // Date started (Unix timestamp)
        1620086400, // Date completed (Unix timestamp)
        'Traditional kintsugi technique with lacquer and gold powder',
        'Urushi lacquer, pure gold powder, wheat flour paste',
        'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG' // Restorer
    );
    
    expect(result.success).toBe(true);
    expect(result.value).toBe(1); // First restoration
    
    const count = mockClarity.getRestorationCount(1);
    expect(count.count).toBe(1);
    
    const restoration = mockClarity.getRestoration(1, 1);
    expect(restoration).not.toBeNull();
    expect(restoration.description).toBe('Repaired crack in base and restored missing glaze');
    expect(restoration['techniques-used']).toBe('Traditional kintsugi technique with lacquer and gold powder');
  });
  
  it('should not allow unapproved restorers to record restorations', () => {
    const result = mockClarity.recordRestoration(
        1,
        'Unauthorized restoration attempt',
        1620000000,
        1620086400,
        'Unknown techniques',
        'Unknown materials',
        'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5YC7WZ5EN' // Not an approved restorer
    );
    
    expect(result.success).toBe(false);
    expect(result.error).toBe(401);
  });
});
