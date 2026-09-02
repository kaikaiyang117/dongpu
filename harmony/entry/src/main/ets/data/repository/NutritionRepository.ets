import { relationalStore } from '@kit.ArkData';
import { FoodEntry, NutritionSummary, QuickFood } from '../../domain/nutrition/NutritionModels';
import { AppDatabase } from '../database/AppDatabase';

export class NutritionRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async getQuickFoods(enabledOnly: boolean = true): Promise<QuickFood[]> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, name, serving_name, calories, protein_g, carbs_g, fat_g, is_builtin, is_enabled
       FROM quick_food ${enabledOnly ? 'WHERE is_enabled = 1 ' : ''}ORDER BY is_builtin DESC, id ASC`
    );
    const foods: QuickFood[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          foods.push(new QuickFood(result.getLong(0), result.getString(1), result.getString(2), result.getDouble(3),
            result.getDouble(4), result.getDouble(5), result.getDouble(6), result.getLong(7) === 1,
            result.getLong(8) === 1));
        } while (result.goToNextRow());
      }
      return foods;
    } finally {
      result.close();
    }
  }

  async addQuickFoodEntry(quickFoodId: number, mealType: string, servings: number = 1,
    recordedAt: number = 0): Promise<FoodEntry> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, name, serving_name, calories, protein_g, carbs_g, fat_g
       FROM quick_food WHERE id = ? AND is_enabled = 1`, [quickFoodId]
    );
    let food: QuickFood | undefined;
    try {
      if (result.goToFirstRow()) {
        food = new QuickFood(result.getLong(0), result.getString(1), result.getString(2), result.getDouble(3),
          result.getDouble(4), result.getDouble(5), result.getDouble(6));
      }
    } finally {
      result.close();
    }
    if (food === undefined) {
      throw new Error('Quick food is unavailable');
    }
    const multiplier: number = servings > 0 ? servings : 1;
    return this.addFoodEntry(new FoodEntry(0, recordedAt, mealType, food.name, food.servingName, multiplier,
      food.calories * multiplier, food.proteinG * multiplier, food.carbsG * multiplier, food.fatG * multiplier,
      food.id));
  }

  async addFoodEntry(entry: FoodEntry): Promise<FoodEntry> {
    if (entry.foodName === '' || entry.calories < 0 || entry.proteinG < 0 || entry.servings <= 0) {
      throw new Error('Invalid food entry');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const recordedAt: number = entry.recordedAt > 0 ? entry.recordedAt : Date.now();
    const createdAt: number = entry.createdAt > 0 ? entry.createdAt : Date.now();
    const id: number = await store.insert('food_entry', {
      recorded_at: recordedAt,
      meal_type: entry.mealType,
      food_name: entry.foodName,
      serving_name: entry.servingName,
      servings: entry.servings,
      calories: entry.calories,
      protein_g: entry.proteinG,
      carbs_g: entry.carbsG > 0 ? entry.carbsG : null,
      fat_g: entry.fatG > 0 ? entry.fatG : null,
      quick_food_id: entry.quickFoodId > 0 ? entry.quickFoodId : null,
      created_at: createdAt
    });
    return new FoodEntry(id, recordedAt, entry.mealType, entry.foodName, entry.servingName, entry.servings,
      entry.calories, entry.proteinG, entry.carbsG, entry.fatG, entry.quickFoodId, createdAt);
  }

  async getDailySummary(dayStart: number, dayEnd: number): Promise<NutritionSummary> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT COALESCE(SUM(calories), 0), COALESCE(SUM(protein_g), 0),
       COALESCE(SUM(carbs_g), 0), COALESCE(SUM(fat_g), 0)
       FROM food_entry WHERE recorded_at >= ? AND recorded_at < ?`, [dayStart, dayEnd]
    );
    try {
      if (!result.goToFirstRow()) {
        return new NutritionSummary();
      }
      return new NutritionSummary(result.getDouble(0), result.getDouble(1), result.getDouble(2), result.getDouble(3));
    } finally {
      result.close();
    }
  }

  async getFoodEntries(startAt: number, endAt: number): Promise<FoodEntry[]> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const result: relationalStore.ResultSet = await store.querySql(
      `SELECT id, recorded_at, meal_type, food_name, serving_name, servings, calories, protein_g,
       carbs_g, fat_g, quick_food_id, created_at FROM food_entry
       WHERE recorded_at >= ? AND recorded_at < ? ORDER BY recorded_at ASC, id ASC`, [startAt, endAt]
    );
    const entries: FoodEntry[] = [];
    try {
      if (result.goToFirstRow()) {
        do {
          entries.push(new FoodEntry(result.getLong(0), result.getLong(1), result.getString(2), result.getString(3),
            result.getString(4), result.getDouble(5), result.getDouble(6), result.getDouble(7), result.getDouble(8),
            result.getDouble(9), result.getLong(10), result.getLong(11)));
        } while (result.goToNextRow());
      }
      return entries;
    } finally {
      result.close();
    }
  }

  async createQuickFood(food: QuickFood): Promise<QuickFood> {
    if (food.name === '' || food.servingName === '' || food.calories < 0 || food.proteinG < 0) {
      throw new Error('Invalid quick food');
    }
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    const now: number = Date.now();
    const id: number = await store.insert('quick_food', {
      name: food.name,
      serving_name: food.servingName,
      calories: food.calories,
      protein_g: food.proteinG,
      carbs_g: food.carbsG > 0 ? food.carbsG : null,
      fat_g: food.fatG > 0 ? food.fatG : null,
      is_builtin: 0,
      is_enabled: food.isEnabled ? 1 : 0,
      created_at: now,
      updated_at: now
    });
    return new QuickFood(id, food.name, food.servingName, food.calories, food.proteinG, food.carbsG, food.fatG,
      false, food.isEnabled);
  }

  async disableQuickFood(id: number): Promise<void> {
    const store: relationalStore.RdbStore = await AppDatabase.getStore(this.context);
    await store.executeSql('UPDATE quick_food SET is_enabled = 0, updated_at = ? WHERE id = ? AND is_builtin = 0',
      [Date.now(), id]);
  }
}
