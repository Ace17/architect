
root()
{
  sound(20);
  melody();
  amplify(0.1);
  delay();
}

melody()
{
  let A3 = 220;
  let A4 = 440;
  let C5 = 523.25;
  let E5 = 659.25;
  let A5 = 880;

//  note(A4, 0);
//  note(C5, 2);
//  note(E5, 4);
  
  repeat8(noteN);
}

noteN(i)
{
  let f = i + 1;
  note(440 * f, i*2);
}

note(freq, when)
{
  push(when, 2);
  sine(freq);
  envelope();
  pop();
}

repeat8(f)
{
  f(0);
  f(1);
  f(2);
  f(3);
  f(4);
  f(5);
  f(6);
  f(7);
}