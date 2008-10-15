/***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2007,2008 William N Dortch <bill.dortch@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 ***** END LICENSE BLOCK *****/

package org.cheri.compat;


import java.lang.reflect.Method;
import java.lang.reflect.InvocationTargetException;

import org.cheri.Cheri;

// if even these aren't defined, our version checks will be useless
import org.jruby.Ruby;
import org.jruby.exceptions.RaiseException;

public abstract class JRubyVersionAdapter {

    // adapted methods
    
    public abstract String getAsSymbolString(Ruby runtime, Object obj);
    public abstract String getAsInternedSymbolString(Ruby runtime, Object obj);
    
    public abstract Object getInstanceVariable(Ruby runtime, Object self, String name);
    public abstract Object fastGetInstanceVariable(Ruby runtime, Object self, String internedName);
    
    public abstract Object getBlockAsProc(Ruby runtime, Object block);
    
    public abstract boolean isKindOf(Ruby runtime, Object self, Object module);


    // we should be able to safely keep a static reference to the
    // adapter, assuming we were loaded by the JRuby ClassLoader.
    private static final JRubyVersionAdapter _adapter;
    
    public static JRubyVersionAdapter getAdapter() {
        JRubyVersionAdapter adapter;
        if ((adapter = _adapter) != null) {
            return adapter;
        }
        throw new Cheri.CheriVersionException();
    }
    
    static {
        String version;
        String adapterName;
        JRubyVersionAdapter adapter = null;
        try {
            Class constants = Class.forName("org.jruby.runtime.Constants");
            version = (String)constants.getField("VERSION").get(null);
            if (version.startsWith("1.0") && !version.startsWith("1.0.")) {
                adapterName = "org.cheri.compat.impl.JRuby_1_0_0_Adapter";
            } else if (version.startsWith("1.0.1")) {
                // no incompatible changes (for us) in 1.0.1
                adapterName = "org.cheri.compat.impl.JRuby_1_0_0_Adapter";
            } else if (version.startsWith("1.0.2")) {
                adapterName = "org.cheri.compat.impl.JRuby_1_0_2_Adapter";
            } else if (version.startsWith("1.0.3")) {
                adapterName = "org.cheri.compat.impl.JRuby_1_0_2_Adapter";
            } else if (version.startsWith("1.0.")) {
                // other 1.0.x, we'll hope this one still works
                adapterName = "org.cheri.compat.impl.JRuby_1_0_2_Adapter";
            } else if (version.startsWith("1.1")) {
                adapterName = "org.cheri.compat.impl.JRuby_1_1_0_Adapter";
            } else if (version.startsWith("1.")) {
                // other 1.x, we'll hope this one still works
                adapterName = "org.cheri.compat.impl.JRuby_1_1_0_Adapter";
            } else {
                // no way we'll work with 2.0 or later, but we'll
                // plug in our latest and cross our fingers anyway
                System.err.println("Warning: Cheri version " + Cheri.VERSION + 
                        " has no suitable adapter for JRuby version " + version);
                adapterName = "org.cheri.compat.impl.JRuby_1_1_0_Adapter";
            }
            adapter = (JRubyVersionAdapter)Class.forName(adapterName).newInstance();
        } catch (IllegalAccessException e) {
        } catch (NoSuchFieldException e) {
        } catch (ClassNotFoundException e) {
        } catch (InstantiationException e) {
        }
        _adapter = adapter;
    }
    
    public static RaiseException newCheriVersionError(Ruby runtime) {
        String msg = "Incompatible JRuby version for Cheri version " + Cheri.VERSION;
        try {
            Class c = runtime.getClass();
            Method m = c.getMethod("newTypeError", new Class[] { String.class });
            return (RaiseException)m.invoke(runtime, new Object[] { msg });
        } catch (NoSuchMethodException e) {
            throw new Cheri.CheriVersionException();
        } catch (IllegalAccessException e) {
            throw new Cheri.CheriVersionException();
        } catch (InvocationTargetException e) {
            throw new Cheri.CheriVersionException();
        }
    }    

}
