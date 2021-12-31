﻿using System;
using System.Reflection;
using SolarWinds.Net.SNMP;
namespace Log4NetSolarWindsSNMP
{
    class Program
    {
        static void Main(string[] args)
        {
            AppDomain currentDomain = AppDomain.CurrentDomain;
            currentDomain.AssemblyResolve += new ResolveEventHandler(MyResolveEventHandler);
            currentDomain.AssemblyLoad += new AssemblyLoadEventHandler(MyLoadEventHandler);

                Console.WriteLine("Solarwinds SNMP start");
                SNMPPriv snmpPriv = SNMPPriv.None;
                SNMPAuth snmpAuth = SNMPAuth.None;
                SNMPRequest request = new SNMPRequest();
                request.SessionHandle.AuthType = snmpAuth;
                request.SessionHandle.PrivacyType = snmpPriv;
/*           } catch (Exception ex)
            {
                Console.WriteLine("Exception: " + ex.Message);
                return;
            }*/
            Console.WriteLine("Solarwinds SNMP end");
        }
        private static Assembly MyResolveEventHandler(object sender, ResolveEventArgs args)
        {
            Console.WriteLine("Resolving..." + args.Name);
            Assembly dll = null;
            if (args.Name.Contains("log4net"))
            {
                string log4netLocation = AppDomain.CurrentDomain.BaseDirectory + "log4net.dll";
                Console.WriteLine(log4netLocation);
                dll = Assembly.LoadFrom(log4netLocation);
            }
            return dll;
        }
        private static void  MyLoadEventHandler(object sender, AssemblyLoadEventArgs args)
        {
            Console.WriteLine("MyLoadEventHandler: " + args.LoadedAssembly.GetName());
        }
    }
}