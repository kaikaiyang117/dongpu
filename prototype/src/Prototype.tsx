import { CheckIcon, ChevronLeftIcon, Cross2Icon, DragHandleDots2Icon, MinusIcon, PlusIcon } from "@radix-ui/react-icons";
import { createContext, useContext, useMemo, useState, type ReactNode } from "react";
import { FlowStack, MobileScroll, type FlowControls, type FlowScreen } from "./mobile";
import "./prototype.css";

type PartId = "chest" | "back" | "shoulders" | "arms" | "legs" | "core";
type Part = { id: PartId; name: string; image: string };
type Exercise = { id: string; name: string; part: PartId; equipment: string; cue: string; recommended?: boolean };
type Setting = { sets: number; reps: number };

const parts: Part[] = [
  { id: "chest", name: "胸部", image: "/assets/body-parts/chest.png" },
  { id: "back", name: "背部", image: "/assets/body-parts/back.png" },
  { id: "shoulders", name: "肩部", image: "/assets/body-parts/shoulders.png" },
  { id: "arms", name: "手臂", image: "/assets/body-parts/arms.png" },
  { id: "legs", name: "腿部", image: "/assets/body-parts/legs.png" },
  { id: "core", name: "核心", image: "/assets/body-parts/core.png" },
];

const exercises: Exercise[] = [
  { id: "seated-chest-press", name: "坐姿推胸", part: "chest", equipment: "推胸机", cue: "肩胛贴紧靠背，向前推至手臂自然伸直", recommended: true },
  { id: "incline-chest-press", name: "上斜推胸", part: "chest", equipment: "上斜推胸机", cue: "手柄对准上胸，慢慢还原" },
  { id: "pec-deck", name: "蝴蝶机夹胸", part: "chest", equipment: "蝴蝶机", cue: "肘部微屈，在胸前缓慢合拢" },
  { id: "lat-pulldown", name: "高位下拉", part: "back", equipment: "高位下拉器", cue: "挺胸，将横杆拉向锁骨", recommended: true },
  { id: "seated-row", name: "坐姿划船", part: "back", equipment: "划船机", cue: "肘部贴近身体，拉向腰侧" },
  { id: "assisted-pullup", name: "辅助引体", part: "back", equipment: "辅助引体机", cue: "保持身体稳定，用背部带动上拉" },
  { id: "machine-shoulder-press", name: "器械推肩", part: "shoulders", equipment: "推肩机", cue: "背部贴紧，向上推至肘部微屈", recommended: true },
  { id: "lateral-raise", name: "哑铃侧平举", part: "shoulders", equipment: "轻哑铃", cue: "用轻重量，抬至与肩同高" },
  { id: "cable-curl", name: "绳索弯举", part: "arms", equipment: "龙门架", cue: "固定上臂，弯曲肘部", recommended: true },
  { id: "triceps-pushdown", name: "绳索下压", part: "arms", equipment: "龙门架", cue: "肘部夹紧身体，向下伸直" },
  { id: "leg-press", name: "腿举", part: "legs", equipment: "腿举机", cue: "膝盖跟随脚尖方向，缓慢下放", recommended: true },
  { id: "leg-extension", name: "腿屈伸", part: "legs", equipment: "腿屈伸机", cue: "调整轴心对准膝盖，伸直后停顿" },
  { id: "leg-curl", name: "腿弯举", part: "legs", equipment: "腿弯举机", cue: "保持髋部稳定，脚跟向后收" },
  { id: "machine-crunch", name: "器械卷腹", part: "core", equipment: "卷腹机", cue: "收紧腹部，不要用手臂拉动", recommended: true },
  { id: "cable-crunch", name: "绳索卷腹", part: "core", equipment: "龙门架", cue: "骨盆稳定，用腹部向下卷曲" },
];

type WorkoutValue = {
  selectedParts: PartId[];
  selectedExercises: string[];
  settings: Record<string, Setting>;
  togglePart: (id: PartId) => void;
  toggleExercise: (id: string) => void;
  updateSetting: (id: string, key: keyof Setting, delta: number) => void;
};

const WorkoutContext = createContext<WorkoutValue | null>(null);

function useWorkout() {
  const value = useContext(WorkoutContext);
  if (!value) throw new Error("WorkoutContext is missing");
  return value;
}

function StepProgress({ active }: { active: 1 | 2 | 3 }) {
  return (
    <div className="step-progress" aria-label={`第 ${active} 步，共 3 步`}>
      {[1, 2, 3].map((step) => (
        <div className="step-group" key={step}>
          <span className={`step-dot ${step <= active ? "is-active" : ""}`}>{step < active ? <CheckIcon /> : step}</span>
          {step < 3 ? <span className={`step-line ${step < active ? "is-active" : ""}`} /> : null}
        </div>
      ))}
    </div>
  );
}

function TopBar({ title, flow, close = false }: { title: string; flow?: FlowControls; close?: boolean }) {
  return (
    <div className="top-bar">
      {flow?.canGoBack ? (
        <button className="top-icon-button" onClick={flow.pop} aria-label={close ? "关闭" : "返回"}>
          {close ? <Cross2Icon /> : <ChevronLeftIcon />}
        </button>
      ) : <span className="top-icon-spacer" />}
      <span className="top-bar-title">{title}</span>
      <span className="top-icon-spacer" />
    </div>
  );
}

function PrimaryFooter({ children, onClick, disabled = false }: { children: ReactNode; onClick: () => void; disabled?: boolean }) {
  return <div className="primary-footer"><button className="primary-button" onClick={onClick} disabled={disabled}>{children}</button></div>;
}

function BodyPartScreen() {
  const { selectedParts, togglePart } = useWorkout();
  return (
    <MobileScroll className="app-screen warm-screen">
      <main className="screen-content body-screen-content">
        <StepProgress active={1} />
        <section className="hero-copy">
          <p className="eyebrow">第 1 步 · 训练部位</p>
          <h1>今天想练哪里？</h1>
          <p>建议选择 1—2 个部位，动作会更专注</p>
        </section>
        <section className="body-grid" aria-label="选择训练部位">
          {parts.map((part) => {
            const selected = selectedParts.includes(part.id);
            return (
              <button className={`body-card ${selected ? "is-selected" : ""}`} key={part.id} onClick={() => togglePart(part.id)} aria-pressed={selected}>
                <span className="body-card-check">{selected ? <CheckIcon /> : null}</span>
                <img src={part.image} alt="" />
                <span>{part.name}</span>
              </button>
            );
          })}
        </section>
        {selectedParts.length === 2 ? <p className="selection-hint">已选 2 个部位，可进入下一步</p> : null}
      </main>
    </MobileScroll>
  );
}

function ExerciseScreen() {
  const { selectedParts, selectedExercises, toggleExercise } = useWorkout();
  const visibleExercises = exercises.filter((exercise) => selectedParts.includes(exercise.part));
  return (
    <MobileScroll className="app-screen warm-screen">
      <main className="screen-content list-screen-content">
        <StepProgress active={2} />
        <section className="hero-copy compact-hero">
          <p className="eyebrow">第 2 步 · 选择动作</p>
          <h1>选择今天的动作</h1>
          <p>新手建议每个部位 2—3 个动作</p>
        </section>
        <div className="part-chip-row">
          {selectedParts.map((id) => <span className="part-chip" key={id}>{parts.find((part) => part.id === id)?.name}</span>)}
        </div>
        <section className="exercise-list" aria-label="动作列表">
          {visibleExercises.map((exercise) => {
            const selected = selectedExercises.includes(exercise.id);
            return (
              <button className={`exercise-row ${selected ? "is-selected" : ""}`} key={exercise.id} onClick={() => toggleExercise(exercise.id)} aria-pressed={selected}>
                <span className="exercise-muscle-mark"><img src={parts.find((part) => part.id === exercise.part)?.image} alt="" /></span>
                <span className="exercise-copy">
                  <span className="exercise-title-line"><strong>{exercise.name}</strong>{exercise.recommended ? <small>推荐</small> : null}</span>
                  <span>{exercise.equipment} · {exercise.cue}</span>
                </span>
                <span className="round-check">{selected ? <CheckIcon /> : <PlusIcon />}</span>
              </button>
            );
          })}
        </section>
      </main>
    </MobileScroll>
  );
}

function NumberControl({ value, onDecrease, onIncrease, label }: { value: number; onDecrease: () => void; onIncrease: () => void; label: string }) {
  return (
    <div className="number-control" aria-label={label}>
      <button onClick={onDecrease} aria-label={`减少${label}`}><MinusIcon /></button><span>{value}</span><button onClick={onIncrease} aria-label={`增加${label}`}><PlusIcon /></button>
    </div>
  );
}

function ConfirmScreen({ flow }: { flow: FlowControls }) {
  const { selectedExercises, settings, updateSetting, toggleExercise } = useWorkout();
  const selected = selectedExercises.map((id) => exercises.find((exercise) => exercise.id === id)).filter(Boolean) as Exercise[];
  const totalSets = selected.reduce((total, exercise) => total + settings[exercise.id].sets, 0);
  return (
    <MobileScroll className="app-screen warm-screen">
      <main className="screen-content confirm-screen-content">
        <StepProgress active={3} />
        <section className="hero-copy compact-hero">
          <p className="eyebrow">第 3 步 · 确认计划</p><h1>今天就按这个练</h1><p>{selected.length} 个动作 · {totalSets} 组 · 约 {Math.max(20, selected.length * 7)} 分钟</p>
        </section>
        <section className="plan-list" aria-label="今日训练计划">
          {selected.map((exercise, index) => (
            <article className="plan-row" key={exercise.id}>
              <DragHandleDots2Icon className="drag-icon" /><div className="plan-order">{String(index + 1).padStart(2, "0")}</div>
              <div className="plan-main">
                <div className="plan-name-line"><strong>{exercise.name}</strong><button className="remove-button" onClick={() => toggleExercise(exercise.id)} aria-label={`移除${exercise.name}`}><Cross2Icon /></button></div>
                <span>{exercise.equipment}</span>
                <div className="setting-row">
                  <label>组数 <NumberControl value={settings[exercise.id].sets} label="组数" onDecrease={() => updateSetting(exercise.id, "sets", -1)} onIncrease={() => updateSetting(exercise.id, "sets", 1)} /></label>
                  <label>次数 <NumberControl value={settings[exercise.id].reps} label="次数" onDecrease={() => updateSetting(exercise.id, "reps", -1)} onIncrease={() => updateSetting(exercise.id, "reps", 1)} /></label>
                </div>
              </div>
            </article>
          ))}
        </section>
        <button className="edit-action-button" onClick={flow.pop}><PlusIcon /> 添加或修改动作</button>
      </main>
    </MobileScroll>
  );
}

function ReadyScreen({ flow }: { flow: FlowControls }) {
  const { selectedExercises, settings } = useWorkout();
  const selected = selectedExercises.map((id) => exercises.find((exercise) => exercise.id === id)).filter(Boolean) as Exercise[];
  const totalSets = selected.reduce((total, exercise) => total + settings[exercise.id].sets, 0);
  return (
    <MobileScroll className="app-screen ready-screen">
      <main className="ready-content">
        <div className="ready-check"><CheckIcon /></div><p className="eyebrow">计划已准备好</p><h1>开始今天的训练</h1><p>先从轻重量热身，感觉动作稳定后再慢慢加重。</p>
        <div className="ready-summary"><span><strong>{selected.length}</strong> 个动作</span><span><strong>{totalSets}</strong> 组</span><span><strong>{Math.max(20, selected.length * 7)}</strong> 分钟</span></div>
        <ol className="ready-list">{selected.map((exercise, index) => <li key={exercise.id}><span>{index + 1}</span>{exercise.name}</li>)}</ol>
        <button className="secondary-button" onClick={flow.pop}>返回调整计划</button>
      </main>
    </MobileScroll>
  );
}

const bodyScreen: FlowScreen = { id: "body", headerHeight: 54, header: () => <TopBar title="自定义训练" />, footerHeight: 104, footer: (flow) => <BodyFooter flow={flow} />, render: () => <BodyPartScreen /> };
const exerciseScreen: FlowScreen = { id: "exercise", headerHeight: 54, header: (flow) => <TopBar title="选择动作" flow={flow} />, footerHeight: 104, footer: (flow) => <ExerciseFooter flow={flow} />, render: () => <ExerciseScreen /> };
const confirmScreen: FlowScreen = { id: "confirm", headerHeight: 54, header: (flow) => <TopBar title="确认计划" flow={flow} />, footerHeight: 104, footer: (flow) => <ConfirmFooter flow={flow} />, render: (flow) => <ConfirmScreen flow={flow} /> };
const readyScreen: FlowScreen = { id: "ready", headerHeight: 54, header: (flow) => <TopBar title="今日训练" flow={flow} close />, render: (flow) => <ReadyScreen flow={flow} /> };

function BodyFooter({ flow }: { flow: FlowControls }) {
  const { selectedParts } = useWorkout();
  return <PrimaryFooter disabled={!selectedParts.length} onClick={() => flow.push(exerciseScreen)}>下一步 · 选择动作</PrimaryFooter>;
}

function ExerciseFooter({ flow }: { flow: FlowControls }) {
  const { selectedExercises } = useWorkout();
  return <PrimaryFooter disabled={!selectedExercises.length} onClick={() => flow.push(confirmScreen)}>下一步 · 确认计划（{selectedExercises.length}）</PrimaryFooter>;
}

function ConfirmFooter({ flow }: { flow: FlowControls }) {
  const { selectedExercises } = useWorkout();
  return <PrimaryFooter disabled={!selectedExercises.length} onClick={() => flow.push(readyScreen)}>开始训练</PrimaryFooter>;
}

export default function Prototype() {
  const [selectedParts, setSelectedParts] = useState<PartId[]>(["chest"]);
  const [selectedExercises, setSelectedExercises] = useState<string[]>([]);
  const [settings, setSettings] = useState<Record<string, Setting>>(() => Object.fromEntries(exercises.map((exercise) => [exercise.id, { sets: 3, reps: 10 }])));
  const value = useMemo<WorkoutValue>(() => ({
    selectedParts,
    selectedExercises,
    settings,
    togglePart: (id) => setSelectedParts((current) => {
      if (current.includes(id)) {
        setSelectedExercises((selected) => selected.filter((exerciseId) => exercises.find((exercise) => exercise.id === exerciseId)?.part !== id));
        return current.filter((part) => part !== id);
      }
      if (current.length >= 2) return [current[1], id];
      return [...current, id];
    }),
    toggleExercise: (id) => setSelectedExercises((current) => current.includes(id) ? current.filter((item) => item !== id) : [...current, id]),
    updateSetting: (id, key, delta) => setSettings((current) => ({ ...current, [id]: { ...current[id], [key]: Math.max(key === "sets" ? 1 : 6, Math.min(key === "sets" ? 6 : 20, current[id][key] + delta)) } })),
  }), [selectedExercises, selectedParts, settings]);
  return <WorkoutContext.Provider value={value}><FlowStack initial={bodyScreen} /></WorkoutContext.Provider>;
}
