// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The Verilated chip and USB device (usb_board.v) as a Node addon, for
// board.mjs. Time is in picoseconds. The emulated RP2040 calls
// advance(t) to run the hardware up to time t with the inputs last set,
// then set(...) when its pins change, so the hardware sees each input
// change at the instruction that made it.
//
// It also records every change of the USB line (with who drives it), so
// the test can measure the bus timing the device sees.

#include <node_api.h>
#include <cmath>
#include <vector>
#include "Vusb_board.h"
#include "verilated.h"

static VerilatedContext *ctx;
static Vusb_board *top;
static double now_ps = 0, next_clk = 0, next_usb = 0;
static double clk_half_ps, usb_half_ps;  // set by init
static std::vector<double> bus_log;  // [t, state] pairs
static int last_bus = -1;
static unsigned long conflicts = 0;

static void log_bus() {
  int s = top->usb_dp | (top->usb_dm << 1) | (top->host_driving << 2) | (top->bus_conflict << 3);
  if (s != last_bus) {
    bus_log.push_back(now_ps);
    bus_log.push_back(s);
    last_bus = s;
  }
  if (top->bus_conflict) conflicts++;
}

static void run_to(double t) {
  while (true) {
    double e = std::min(next_clk, next_usb);
    if (e > t) break;
    now_ps = e;
    if (next_clk <= e) {
      top->clk = !top->clk;
      next_clk += clk_half_ps;
    }
    if (next_usb <= e) {
      top->usb_clk = !top->usb_clk;
      next_usb += usb_half_ps;
    }
    top->eval();
    log_bus();
  }
  now_ps = t;
}

static double num(napi_env env, napi_value v) {
  double d;
  napi_get_value_double(env, v, &d);
  return d;
}

static napi_value make_num(napi_env env, double d) {
  napi_value v;
  napi_create_double(env, d, &v);
  return v;
}

// init(chip_hz, usb_hz, usb_phase_ps)
static napi_value Init_(napi_env env, napi_callback_info info) {
  size_t argc = 3;
  napi_value a[3];
  napi_get_cb_info(env, info, &argc, a, nullptr, nullptr);
  ctx = new VerilatedContext;
  top = new Vusb_board{ctx};
  clk_half_ps = 1e12 / num(env, a[0]) / 2;
  usb_half_ps = 1e12 / num(env, a[1]) / 2;
  now_ps = 0;
  next_clk = clk_half_ps;
  next_usb = num(env, a[2]) + usb_half_ps;
  top->clk = 0;
  top->usb_clk = 0;
  top->rst_n = 0;
  top->usb_rst = 1;
  top->ui_in = 0;
  top->eval();
  bus_log.clear();
  last_bus = -1;
  conflicts = 0;
  return nullptr;
}

// advance(t_ps) -> uo_out
static napi_value Advance(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value a[1];
  napi_get_cb_info(env, info, &argc, a, nullptr, nullptr);
  double t = num(env, a[0]);
  if (t > now_ps) run_to(t);
  return make_num(env, top->uo_out);
}

// set(ui_in, rst_n, usb_rst) -> uo_out (after the change settles)
static napi_value Set(napi_env env, napi_callback_info info) {
  size_t argc = 3;
  napi_value a[3];
  napi_get_cb_info(env, info, &argc, a, nullptr, nullptr);
  top->ui_in = (int)num(env, a[0]);
  top->rst_n = (int)num(env, a[1]);
  top->usb_rst = (int)num(env, a[2]);
  top->eval();
  log_bus();
  return make_num(env, top->uo_out);
}

// state() -> [now_ps, uo_out, dev_connected, conflicts]
static napi_value State(napi_env env, napi_callback_info info) {
  napi_value arr;
  napi_create_array_with_length(env, 4, &arr);
  double v[4] = {now_ps, (double)top->uo_out, (double)top->dev_connected, (double)conflicts};
  for (int i = 0; i < 4; i++) napi_set_element(env, arr, i, make_num(env, v[i]));
  return arr;
}

// takeBusLog() -> Float64Array of [t_ps, state] pairs since the last call;
// state = D+ | D- << 1 | host driving << 2 | conflict << 3
static napi_value TakeBusLog(napi_env env, napi_callback_info info) {
  size_t n = bus_log.size();
  void *data;
  napi_value ab, ta;
  napi_create_arraybuffer(env, n * sizeof(double), &data, &ab);
  std::copy(bus_log.begin(), bus_log.end(), (double *)data);
  napi_create_typedarray(env, napi_float64_array, n, ab, 0, &ta);
  bus_log.clear();
  return ta;
}

static napi_value Module(napi_env env, napi_value exports) {
  napi_property_descriptor d[] = {
      {"init", 0, Init_, 0, 0, 0, napi_default, 0},
      {"advance", 0, Advance, 0, 0, 0, napi_default, 0},
      {"set", 0, Set, 0, 0, 0, napi_default, 0},
      {"state", 0, State, 0, 0, 0, napi_default, 0},
      {"takeBusLog", 0, TakeBusLog, 0, 0, 0, napi_default, 0},
  };
  napi_define_properties(env, exports, 5, d);
  return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Module)
