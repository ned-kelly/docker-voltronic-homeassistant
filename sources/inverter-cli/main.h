#ifndef ___MAIN_H
#define ___MAIN_H

#include <atomic>
#include "inverter.h"

extern bool debugFlag;
extern atomic_bool ups_data_changed;

extern atomic_bool ups_status_changed;
extern atomic_bool ups_qpiws_changed;
extern atomic_bool ups_qmod_changed;
extern atomic_bool ups_qpiri_changed;
extern atomic_bool ups_qpigs_changed;

#endif // ___MAIN_H
