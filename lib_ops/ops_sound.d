/**
 * @file ops_sound.d
 * @brief Sound processing/synthesis part
 * @author Sebastien Alaiwan
 * @date 2015-11-07
 */

/*
 * Copyright (C) 2015 - Sebastien Alaiwan
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 */

import std.math;
import std.algorithm;
import misc: clamp;

import loader;
import value;
import dashboard_sound;

void op_sound(EditionState state, Value[] values)
{
  if(values.length != 1)
    throw new Exception("sound takes 1 one argument");

  const length = asReal(values[0]);
  auto sound = new Sound;
  sound.samples.length = max(SAMPLE_RATE, cast(int)(SAMPLE_RATE * length));
  sound.samples[] = 0;
  state.board = sound;
}

void op_sine(Sound sound, float freq, float t, float duration)
{
  auto wnd = sound_window(sound, t, duration);

  foreach(i, ref s; wnd)
    s = sin(i * freq * (2 * PI) / SAMPLE_RATE);
}

void op_square(Sound sound, float freq)
{
  foreach(i, ref s; sound.samples)
    s = dsp_square(i * freq * (2 * PI) / SAMPLE_RATE);
}

void op_envelope(Sound sound, float t, float duration)
{
  auto wnd = sound_window(sound, t, duration);

  foreach(i, ref s; wnd)
  {
    float f = 1 - cast(float)i / cast(float)wnd.length;
    s *= f * f * f;
  }
}

void op_amplify(Sound sound, float amp)
{
  foreach(i, ref s; sound.samples)
    s *= amp;
}

void op_delay(Sound sound)
{
  const duration = SAMPLE_RATE;

  foreach(i, ref s; sound.samples[duration .. $])
    s += sound.samples[i] * 0.3;
}

float dsp_square(float f)
{
  auto phase = fmod(f, 2 * PI);
  return phase > PI;
}

float[] sound_window(Sound sound, float t, float duration)
{
  const left = clamp(cast(int)(t * SAMPLE_RATE), 0, sound.samples.length);
  const right = clamp(cast(int)((t + duration) * SAMPLE_RATE), 0, sound.samples.length);
  return sound.samples[left .. right];
}

static this()
{
  g_Operations["sound"] = &op_sound;

  registerRealizeFunc!(op_sine, "sine")();
  registerRealizeFunc!(op_square, "square")();
  registerRealizeFunc!(op_amplify, "amplify")();
  registerRealizeFunc!(op_envelope, "envelope")();
  registerRealizeFunc!(op_delay, "delay")();
}

