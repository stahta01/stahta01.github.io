/***************************************************************
 * Name:      wx30_gcc471TDM_dllMain.h
 * Purpose:   Defines Application Frame
 * Author:     ()
 * Created:   2015-01-14
 * Copyright:  ()
 * License:
 **************************************************************/

#ifndef WX30_GCC471TDM_DLLMAIN_H
#define WX30_GCC471TDM_DLLMAIN_H

#ifndef WX_PRECOMP
    #include <wx/wx.h>
#endif

#include "wx30_gcc471TDM_dllApp.h"

class wx30_gcc471TDM_dllFrame: public wxFrame
{
    public:
        wx30_gcc471TDM_dllFrame(wxFrame *frame, const wxString& title);
        ~wx30_gcc471TDM_dllFrame();
    private:
        enum
        {
            idMenuQuit = 1000,
            idMenuAbout
        };
        void OnClose(wxCloseEvent& event);
        void OnQuit(wxCommandEvent& event);
        void OnAbout(wxCommandEvent& event);
        DECLARE_EVENT_TABLE()
};


#endif // WX30_GCC471TDM_DLLMAIN_H
