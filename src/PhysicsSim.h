// -*- mode:c++; indent-tabs-mode:nil; c-basic-offset:4; compile-command:"scons debug=1" -*-

#ifndef _PHYSICS_SIM_H_
#define _PHYSICS_SIM_H_

#include "Simulation.h"

class PhysicsSim : public Simulation
{
  public:
    PhysicsSim(const char *port);
    virtual ~PhysicsSim();

  protected:
};

class PhysicsPrismFactory : public PrismFactory
{
public:
    PhysicsPrismFactory(Simulation *parent) : PrismFactory(parent) {}
    virtual ~PhysicsPrismFactory() {}

    virtual PhysicsSim* simulation() { return static_cast<PhysicsSim*>(m_parent); }

protected:
    bool create(const char *name, float x, float y, float z);
};

class PhysicsSphereFactory : public SphereFactory
{
public:
    PhysicsSphereFactory(Simulation *parent) : SphereFactory(parent) {}
    virtual ~PhysicsSphereFactory() {}

    virtual PhysicsSim* simulation() { return static_cast<PhysicsSim*>(m_parent); }

protected:
    bool create(const char *name, float x, float y, float z);
};

class ODEObject
{
public:
    ODEObject(dWorldID &odeWorld, dSpaceID &odeSpace);
    virtual ~ODEObject();

protected:
    dBodyID  m_odeBody;
    dGeomID  m_odeGeom;
    dMass	 m_odeMass;
    dWorldID m_odeWorld;
    dSpaceID m_odeSpace;
};

class OscSphereODE : public OscSphere, public ODEObject
{
public:
	OscSphereODE(dWorldID &odeWorld, dSpaceID &odeSpace, const char *name, OscBase *parent=NULL);
    virtual ~OscSphereODE() {}

protected:
    virtual void onSetRadius();
};

#endif // _PHYSICS_SIM_H_
