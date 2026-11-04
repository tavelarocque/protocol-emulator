// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The Verilated chip and its devices (board.v) as a Node addon, for
// board.mjs. Time is in picoseconds. The emulated RP2040 calls advance(t)
// to run the hardware up to time t with the inputs last set, and set...()
// when its pins (or a JavaScript device's) change, so the hardware sees each
// change at the instruction that made it.
//
// It also records every change of the USB line, with who drives it, so the
// test can measure the bus timing the device sees.

#include <node_api.h>
#include <string>
#include <vector>
#include "Vboard.h"
#include "verilated.h"

static VerilatedContext *ctx;
static Vboard *top;
static double now_ps, next_clk, next_usb, clk_half_ps, usb_half_ps;
static bool usb_on;
static std::vector<double> bus_log;  // [t, state] pairs
static int last_bus;
static unsigned long conflicts;

static void log_bus() {
  if (!usb_on) return;
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
    double e = usb_on ? std::min(next_clk, next_usb) : next_clk;
    if (e > t) break;
    now_ps = e;
    if (next_clk <= e) {
      top->clk = !top->clk;
      next_clk += clk_half_ps;
    }
    if (usb_on && next_usb <= e) {
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

#define ARGS(n)                                              \
  size_t argc = n;                                           \
  napi_value a[n];                                           \
  napi_get_cb_info(env, info, &argc, a, nullptr, nullptr)

// init(chip_hz, usb_hz (0: no USB clock), flash_hex_path, start_ps)
static napi_value Init_(napi_env env, napi_callback_info info) {
  ARGS(4);
  char path[1024] = "";
  size_t len = 0;
  napi_get_value_string_utf8(env, a[2], path, sizeof path, &len);
  if (top) {
    top->final();
    delete top;
    delete ctx;
  }
  ctx = new VerilatedContext;
  std::string arg = std::string("+firmware=") + path;
  const char *argv[] = {"cosim", arg.c_str()};
  ctx->commandArgs(2, argv);
  top = new Vboard{ctx};
  double usb_hz = num(env, a[1]);
  usb_on = usb_hz > 0;
  clk_half_ps = 1e12 / num(env, a[0]) / 2;
  usb_half_ps = usb_on ? 1e12 / usb_hz / 2 : 1;
  now_ps = num(env, a[3]);
  next_clk = now_ps + clk_half_ps;
  next_usb = now_ps + 3333 + usb_half_ps;  // the two clocks are not in phase
  top->clk = 0;
  top->usb_clk = 0;
  top->rst_n = 0;
  top->usb_rst = 1;
  top->ui_in = 0;
  top->dev_mode = 0;
  top->i2c_sda_dev = 1;
  top->i2c_scl_dev = 1;
  top->uart_rx = 1;
  top->spi_sclk = 0;
  top->spi_mosi = 1;
  top->spi_cs_n = 1;
  top->eval();
  bus_log.clear();
  last_bus = -1;
  conflicts = 0;
  return nullptr;
}

static napi_value outputs(napi_env env) {
  // uo_out | uio_out << 8 | uio_oe << 16 | sda << 24 | scl << 25
  double v = top->uo_out | (top->uio_out << 8) | (top->uio_oe << 16) |
             (top->i2c_sda << 24) | (top->i2c_scl << 25);
  return make_num(env, v);
}

// advance(t_ps) -> outputs
static napi_value Advance(napi_env env, napi_callback_info info) {
  ARGS(1);
  double t = num(env, a[0]);
  if (t > now_ps) run_to(t);
  return outputs(env);
}

// set(ui_in, rst_n, usb_rst) -> outputs
static napi_value Set(napi_env env, napi_callback_info info) {
  ARGS(3);
  top->ui_in = (int)num(env, a[0]);
  top->rst_n = (int)num(env, a[1]);
  top->usb_rst = (int)num(env, a[2]);
  top->eval();
  log_bus();
  return outputs(env);
}

// setDev(mode, pins) -> outputs; pins: sda_dev | scl_dev << 1 | uart_rx << 2
// | spi_sclk << 3 | spi_mosi << 4 | spi_cs_n << 5
static napi_value SetDev(napi_env env, napi_callback_info info) {
  ARGS(2);
  int p = (int)num(env, a[1]);
  top->dev_mode = (int)num(env, a[0]);
  top->i2c_sda_dev = p & 1;
  top->i2c_scl_dev = (p >> 1) & 1;
  top->uart_rx = (p >> 2) & 1;
  top->spi_sclk = (p >> 3) & 1;
  top->spi_mosi = (p >> 4) & 1;
  top->spi_cs_n = (p >> 5) & 1;
  top->eval();
  return outputs(env);
}

// state() -> [now_ps, outputs, usb device connected, bus conflicts,
// SWD parity errors]
static napi_value State(napi_env env, napi_callback_info info) {
  napi_value arr;
  napi_create_array_with_length(env, 5, &arr);
  double v[5] = {now_ps, 0, (double)top->dev_connected, (double)conflicts,
                 (double)top->swd_parity_errors};
  for (int i = 0; i < 5; i++)
    napi_set_element(env, arr, i, i == 1 ? outputs(env) : make_num(env, v[i]));
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
      {"setDev", 0, SetDev, 0, 0, 0, napi_default, 0},
      {"state", 0, State, 0, 0, 0, napi_default, 0},
      {"takeBusLog", 0, TakeBusLog, 0, 0, 0, napi_default, 0},
  };
  napi_define_properties(env, exports, 6, d);
  return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Module)
