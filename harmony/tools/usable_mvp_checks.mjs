#!/usr/bin/env node

import assert from 'node:assert/strict';

const State = Object.freeze({
  ACTIVE: 'active',
  REQUIRED: 'required',
  OPTIONAL: 'optional',
  RECOVERY: 'recovery',
  COMPLETED: 'completed'
});

function decideTodayPlan({ active = false, completedToday = false, requiredCompleted = 0,
  requiredTarget = 3, preferredFrequency = 3, optionalCompleted = false }) {
  if (active) return State.ACTIVE;
  if (completedToday) return State.COMPLETED;
  if (requiredCompleted < requiredTarget) return State.REQUIRED;
  if (preferredFrequency >= 4 && !optionalCompleted) return State.OPTIONAL;
  return State.RECOVERY;
}

assert.equal(decideTodayPlan({ requiredCompleted: 0 }), State.REQUIRED);
assert.equal(decideTodayPlan({ requiredCompleted: 1 }), State.REQUIRED);
assert.equal(decideTodayPlan({ requiredCompleted: 2 }), State.REQUIRED);
assert.equal(decideTodayPlan({ requiredCompleted: 3, preferredFrequency: 3 }), State.RECOVERY);
assert.equal(decideTodayPlan({ requiredCompleted: 3, preferredFrequency: 4 }), State.OPTIONAL);
assert.equal(decideTodayPlan({ requiredCompleted: 3, preferredFrequency: 4, optionalCompleted: true }), State.RECOVERY);
assert.equal(decideTodayPlan({ active: true, requiredCompleted: 3 }), State.ACTIVE);
assert.equal(decideTodayPlan({ completedToday: true, requiredCompleted: 1 }), State.COMPLETED);

const kgPerLb = 0.45359237;
assert.equal(Number((82 / kgPerLb).toFixed(1)), 180.8);
assert.ok(Math.abs(180.8 * kgPerLb - 82) < 0.05);

function progression(weight, reps, repMax, increment, bodyweight) {
  const allAtTop = reps.every((value) => value >= repMax);
  return allAtTop && !bodyweight ? weight + increment : weight;
}

assert.equal(progression(50, [12, 12, 12], 12, 2.5, false), 52.5);
assert.equal(progression(50, [12, 11, 12], 12, 2.5, false), 50);
assert.equal(progression(0, [12, 12, 12], 12, 2.5, true), 0);

function trendStatus(changePercent) {
  if (changePercent < -1) return 'fast';
  if (changePercent <= -0.25) return 'normal';
  return 'slow';
}

assert.equal(trendStatus(-1.2), 'fast');
assert.equal(trendStatus(-0.5), 'normal');
assert.equal(trendStatus(-0.05), 'slow');

let finishCount = 0;
function finishOnce() {
  if (finishCount === 0) finishCount = 1;
}

finishOnce();
finishOnce();
assert.equal(finishCount, 1);

console.log('usable MVP checks: PASS');
