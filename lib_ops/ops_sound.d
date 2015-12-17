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

enum SAMPLE_PERIOD = 1.0 / SAMPLE_RATE;

void op_sound(EditionState state, Value[] values)
{
  if(values.length != 1)
    throw new Exception("sound takes 1 one argument");

  const length = asReal(values[0]);
  auto sound = new Sound;
  sound.samples.length = max(SAMPLE_RATE, cast(int)(SAMPLE_RATE * length));
  sound.samples[] = 0;
  state.board = sound;

  sound.blocks ~= Block(sound.samples);
}

void op_sine(Sound sound, float freq)
{
  float phase = 0;

  foreach(i, ref s; sound.currBlock.samples)
  {
    s = sin(phase);
    phase += freq * (2 * PI) * SAMPLE_PERIOD;

    if(phase > 2 * PI)
      phase -= 2 * PI;
  }
}

void op_square(Sound sound, float freq)
{
  foreach(i, ref s; sound.currBlock.samples)
    s = dsp_square(i * freq * (2 * PI) * SAMPLE_PERIOD);
}

void op_envelope(Sound sound)
{
  const invN = 1.0 / sound.currBlock.samples.length;

  foreach(i, ref s; sound.currBlock.samples)
  {
    float f = 1 - cast(float)i * invN;
    s *= f;
  }
}

void op_amplify(Sound sound, float amp)
{
  foreach(i, ref s; sound.currBlock.samples)
    s *= amp;
}

void op_delay(Sound sound)
{
  const duration = SAMPLE_RATE;

  foreach(i, ref s; sound.samples[duration .. $])
  {
    float r = sound.samples[i] * 0.3;

    if(abs(r) < 0.01)
      r = 0;

    s += r;
  }
}

void op_select(Sound sound, float time, float duration)
{
  auto samples = sound.currBlock().samples;

  const N1 = clamp(cast(int)(time * SAMPLE_RATE), 0, samples.length - 1);
  const N2 = clamp(cast(int)((time + duration) * SAMPLE_RATE), 0, samples.length - 1);

  sound.blocks ~= Block(samples[N1 .. N2]);
}

void op_deselect(Sound sound)
{
  if(sound.blocks.length <= 1)
    throw new Exception("Nothing to deselect");

  sound.blocks.length--;
}

float dsp_square(float f)
{
  auto phase = fmod(f, 2 * PI);
  return phase > PI;
}

static this()
{
  g_Operations["sound"] = RealizeFunc("sound", &op_sound);

  registerRealizeFunc!(op_select, "sound", "push")();
  registerRealizeFunc!(op_deselect, "sound", "pop")();
  registerRealizeFunc!(op_sine, "sound", "sine")();
  registerRealizeFunc!(op_square, "sound", "square")();
  registerRealizeFunc!(op_amplify, "sound", "amplify")();
  registerRealizeFunc!(op_envelope, "sound", "envelope")();
  registerRealizeFunc!(op_delay, "sound", "delay")();
}

