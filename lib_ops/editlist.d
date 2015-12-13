/**
 * @file editlist.d
 * @brief An EditList is the output of the realization of a program.
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

import value;

class EditList
{
  EditOperation[] ops;
}

struct EditOperation
{
  string funcName;
  Value[] args;
}

