const KG_PER_LB: number = 0.45359237;

export function kgToDisplay(kg: number, unit: string): number {
  return unit === 'lb' ? kg / KG_PER_LB : kg;
}

export function displayToKg(value: number, unit: string): number {
  return unit === 'lb' ? value * KG_PER_LB : value;
}

export function inputToKg(value: number, unit: string): number {
  return displayToKg(value, unit);
}

export function formatWeight(kg: number, unit: string, decimals: number = 1): string {
  return `${kgToDisplay(kg, unit).toFixed(decimals)} ${unit === 'lb' ? 'lb' : 'kg'}`;
}

export function formatWeightChange(kg: number, unit: string, decimals: number = 1): string {
  return `${kg >= 0 ? '+' : '-'}${kgToDisplay(Math.abs(kg), unit).toFixed(decimals)} ${unit === 'lb' ? 'lb' : 'kg'}`;
}
