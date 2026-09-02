export class QuickFood {
  id: number;
  name: string;
  servingName: string;
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  isBuiltin: boolean;
  isEnabled: boolean;

  constructor(id: number = 0, name: string = '', servingName: string = '', calories: number = 0,
    proteinG: number = 0, carbsG: number = 0, fatG: number = 0, isBuiltin: boolean = false,
    isEnabled: boolean = true) {
    this.id = id;
    this.name = name;
    this.servingName = servingName;
    this.calories = calories;
    this.proteinG = proteinG;
    this.carbsG = carbsG;
    this.fatG = fatG;
    this.isBuiltin = isBuiltin;
    this.isEnabled = isEnabled;
  }
}

export class FoodEntry {
  id: number;
  recordedAt: number;
  mealType: string;
  foodName: string;
  servingName: string;
  servings: number;
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  quickFoodId: number;
  createdAt: number;

  constructor(id: number = 0, recordedAt: number = 0, mealType: string = 'snack', foodName: string = '',
    servingName: string = '', servings: number = 1, calories: number = 0, proteinG: number = 0,
    carbsG: number = 0, fatG: number = 0, quickFoodId: number = 0, createdAt: number = 0) {
    this.id = id;
    this.recordedAt = recordedAt;
    this.mealType = mealType;
    this.foodName = foodName;
    this.servingName = servingName;
    this.servings = servings;
    this.calories = calories;
    this.proteinG = proteinG;
    this.carbsG = carbsG;
    this.fatG = fatG;
    this.quickFoodId = quickFoodId;
    this.createdAt = createdAt;
  }
}

export class NutritionSummary {
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;

  constructor(calories: number = 0, proteinG: number = 0, carbsG: number = 0, fatG: number = 0) {
    this.calories = calories;
    this.proteinG = proteinG;
    this.carbsG = carbsG;
    this.fatG = fatG;
  }
}
