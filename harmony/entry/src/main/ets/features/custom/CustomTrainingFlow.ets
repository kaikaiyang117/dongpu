import { APP_COLOR_GREEN_DARK } from '../../app/AppTheme';
import { AppRoute } from '../../app/AppRoutes';
import { AppHeader } from '../../components/AppHeader';
import { PrimaryButton } from '../../components/PrimaryButton';
import { StepProgress } from '../../components/StepProgress';
import { exerciseMatchesPart, findExercise, userPartId } from '../../data/ExerciseCatalog';
import { PlanRepository } from '../../data/repository/PlanRepository';
import { BodyPartSelectPage } from './BodyPartSelectPage';
import { ExerciseSelectPage } from './ExerciseSelectPage';
import { PlanConfirmPage } from './PlanConfirmPage';
import { TrainingReadyPage } from './TrainingReadyPage';
import { Exercise } from '../../model/Exercise';
import { PlanItem } from '../../model/WorkoutData';

@Component
export struct CustomTrainingFlow {
  @Prop exercises: Exercise[] = [];
  @Prop route: AppRoute = AppRoute.CustomBody;
  @Prop planRepository: PlanRepository | undefined = undefined;
  @Link selectedParts: string[];
  @Link selectedExerciseIds: string[];
  @Link planItems: PlanItem[];
  @Link customPlanSaved: boolean;
  onStartWorkout: () => void = () => {};
  onNavigate: (route: AppRoute) => void = () => {};

  private title(): string {
    if (this.route === AppRoute.CustomExercise) {
      return '选择动作';
    }
    if (this.route === AppRoute.CustomConfirm) {
      return '确认计划';
    }
    if (this.route === AppRoute.TrainingReady) {
      return '今日训练';
    }
    return '自定义训练';
  }

  private currentStep(): number {
    if (this.route === AppRoute.CustomExercise) {
      return 2;
    }
    if (this.route === AppRoute.CustomConfirm) {
      return 3;
    }
    return 1;
  }

  private isCustomSetup(): boolean {
    return this.route === AppRoute.CustomBody || this.route === AppRoute.CustomExercise ||
      this.route === AppRoute.CustomConfirm;
  }

  private showBack(): boolean {
    return this.route !== AppRoute.CustomBody;
  }

  private backGlyph(): string {
    return this.route === AppRoute.TrainingReady ? '×' : '‹';
  }

  private headerAction(): string {
    return this.route === AppRoute.CustomBody ? '动作' : '';
  }

  private footerText(): string {
    if (this.route === AppRoute.CustomBody) {
      return '下一步 · 选择动作';
    }
    if (this.route === AppRoute.CustomExercise) {
      return `下一步 · 确认计划（${this.selectedExerciseIds.length}）`;
    }
    return '开始训练';
  }

  private canContinue(): boolean {
    if (this.route === AppRoute.CustomBody) {
      return this.selectedParts.length > 0;
    }
    if (this.route === AppRoute.CustomExercise) {
      return this.selectedExerciseIds.length > 0;
    }
    return this.planItems.length > 0;
  }

  private goBack(): void {
    if (this.route === AppRoute.TrainingReady) {
      this.onNavigate(AppRoute.CustomConfirm);
      return;
    }
    if (this.route === AppRoute.CustomConfirm) {
      this.onNavigate(AppRoute.CustomExercise);
      return;
    }
    if (this.route === AppRoute.CustomExercise) {
      this.onNavigate(AppRoute.CustomBody);
    }
  }

  private goNext(): void {
    if (this.route === AppRoute.CustomBody && this.selectedParts.length > 0) {
      this.onNavigate(AppRoute.CustomExercise);
      return;
    }
    if (this.route === AppRoute.CustomExercise && this.selectedExerciseIds.length > 0) {
      this.planItems = this.selectedExerciseIds.map((id: string) => new PlanItem(id));
      this.customPlanSaved = false;
      if (this.planRepository !== undefined) {
        this.planRepository.saveDraft(this.planItems);
      }
      this.onNavigate(AppRoute.CustomConfirm);
      return;
    }
    if (this.route === AppRoute.CustomConfirm && this.planItems.length > 0) {
      this.onStartWorkout();
    }
  }

  private togglePart(id: string): void {
    if (this.selectedParts.includes(id)) {
      this.selectedParts = this.selectedParts.filter((partId: string) => partId !== id);
      this.selectedExerciseIds = this.selectedExerciseIds.filter((exerciseId: string) => {
        return !exerciseMatchesPart(findExercise(this.exercises, exerciseId), id);
      });
      return;
    }
    this.selectedParts = [...this.selectedParts, id];
  }

  private toggleExercise(id: string): void {
    if (this.selectedExerciseIds.includes(id)) {
      this.selectedExerciseIds = this.selectedExerciseIds.filter((exerciseId: string) => exerciseId !== id);
      return;
    }
    this.selectedExerciseIds = [...this.selectedExerciseIds, id];
  }

  private updatePlan(id: string, field: string, delta: number): void {
    this.planItems = this.planItems.map((item: PlanItem) => {
      if (item.exerciseId !== id) {
        return item;
      }
      const sets: number = field === 'sets' ? Math.max(1, Math.min(6, item.sets + delta)) : item.sets;
      const repMin: number = field === 'repMin' ? Math.max(1, Math.min(item.repMax, item.repMin + delta)) :
        item.repMin;
      const repMax: number = field === 'repMax' ? Math.max(repMin, Math.min(30, item.repMax + delta)) : item.repMax;
      const restSeconds: number = field === 'restSeconds' ? Math.max(15,
        Math.min(180, item.restSeconds + delta * 15)) : item.restSeconds;
      return new PlanItem(id, sets, repMin, repMax, restSeconds);
    });
    this.customPlanSaved = false;
  }

  private movePlanItem(id: string, delta: number): void {
    const index: number = this.planItems.findIndex((item: PlanItem) => item.exerciseId === id);
    const nextIndex: number = Math.max(0, Math.min(this.planItems.length - 1, index + delta));
    if (index < 0 || nextIndex === index) {
      return;
    }
    const nextItems: PlanItem[] = [...this.planItems];
    const moved: PlanItem = nextItems[index];
    nextItems.splice(index, 1);
    nextItems.splice(nextIndex, 0, moved);
    this.planItems = nextItems;
    this.customPlanSaved = false;
  }

  private removePlanItem(id: string): void {
    this.planItems = this.planItems.filter((item: PlanItem) => item.exerciseId !== id);
    this.selectedExerciseIds = this.selectedExerciseIds.filter((exerciseId: string) => exerciseId !== id);
    this.customPlanSaved = false;
  }

  private async saveCustomPlan(): Promise<void> {
    if (this.planRepository === undefined || this.planItems.length === 0) {
      return;
    }
    await this.planRepository.savePlan(this.planItems);
    this.customPlanSaved = true;
  }

  build() {
    Column() {
      AppHeader({
        title: this.title(),
        showBack: this.showBack(),
        backGlyph: this.backGlyph(),
        actionLabel: this.headerAction(),
        onBack: () => this.goBack(),
        onAction: () => this.onNavigate(AppRoute.ExerciseLibrary)
      })

      if (this.isCustomSetup()) {
        StepProgress({ currentStep: this.currentStep() })
      }

      if (this.route === AppRoute.CustomBody) {
        BodyPartSelectPage({
          selectedParts: this.selectedParts,
          onTogglePart: (id: string) => this.togglePart(id)
        })
      } else if (this.route === AppRoute.CustomExercise) {
        ExerciseSelectPage({
          exercises: this.exercises,
          selectedParts: this.selectedParts,
          selectedExerciseIds: this.selectedExerciseIds,
          onToggleExercise: (id: string) => this.toggleExercise(id)
        })
      } else if (this.route === AppRoute.CustomConfirm) {
        PlanConfirmPage({
          exercises: this.exercises,
          planItems: this.planItems,
          onUpdatePlan: (id: string, field: string, delta: number) => this.updatePlan(id, field, delta),
          onRemovePlanItem: (id: string) => this.removePlanItem(id),
          onMovePlanItem: (id: string, delta: number) => this.movePlanItem(id, delta),
          onEditExercises: () => this.onNavigate(AppRoute.CustomExercise),
          onSavePlan: () => this.saveCustomPlan(),
          isSaved: this.customPlanSaved
        })
      } else {
        TrainingReadyPage({
          exercises: this.exercises,
          planItems: this.planItems,
          onEditPlan: () => this.onNavigate(AppRoute.CustomConfirm)
        })
      }

      if (this.isCustomSetup()) {
        PrimaryButton({
          title: this.footerText(),
          isEnabled: this.canContinue(),
          onTap: () => this.goNext()
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
