// -*- mode:c++; indent-tabs-mode:nil; c-basic-offset:4; compile-command:"scons debug=1" -*-

#ifndef _PHYSICS_SIM_H_
#define _PHYSICS_SIM_H_

#include "Simulation.h"

class PhysicsSphereFactory : public SphereFactory
{
public:
    PhysicsSphereFactory(Simulation *parent) : SphereFactory(parent) {}
    virtual ~PhysicsSphereFactory() {}

protected:
    bool create(const char *name, float radius);
};

class PhysicsSim : public Simulation
{
  public:
    PhysicsSim(const char *port);
    virtual ~PhysicsSim();

  protected:
};

#endif // _PHYSICS_SIM_H_
