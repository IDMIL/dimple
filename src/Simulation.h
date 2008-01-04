// -*- mode:c++; indent-tabs-mode:nil; c-basic-offset:4; compile-command:"scons debug=1" -*-

#ifndef _SIMULATION_H_
#define _SIMULATION_H_

#include "OscObject.h"

class Simulation;

class ShapeFactory : public OscBase
{
public:
    ShapeFactory(char *name, Simulation *parent);
    virtual ~ShapeFactory();

protected:
    // message handlers
};

class PrismFactory : public ShapeFactory
{
public:
    PrismFactory(Simulation *parent);
    virtual ~PrismFactory();

protected:
    // message handlers
    static int create_handler(const char *path, const char *types, lo_arg **argv,
                              int argc, void *data, void *user_data);
};

class SphereFactory : public ShapeFactory
{
public:
    SphereFactory(Simulation *parent);
    virtual ~SphereFactory();

protected:
    // message handlers
    static int create_handler(const char *path, const char *types, lo_arg **argv,
                              int argc, void *data, void *user_data);

    // override these functions with a specific factory subclass
    virtual bool create(const char *name, float radius) = 0;
};

//! A Simulation is an OSC-controlled simulation thread which contains
//! a scene graph.  It is inherited by the specific simulation, be it
//! physics, haptics, or other.
class Simulation : public OscBase
{
  public:
    Simulation(const char *port);
    virtual ~Simulation();

    PrismFactory *m_pPrismFactory;
    SphereFactory *m_pSphereFactory;

  protected:
    pthread_t m_thread;
    bool m_bDone;

    //! Function for simulation thread
    static void* run(void* param);

    // world objects & constraints
    std::map<std::string,OscObject*> world_objects;
    std::map<std::string,OscConstraint*> world_constraints;
};

#endif // _SIMULATION_H_
