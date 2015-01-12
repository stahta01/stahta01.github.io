/***************************************************************
 * Name:      wx30Main.h
 * Purpose:   Defines Application Frame
 * Author:     ()
 * Created:   2015-01-12
 * Copyright:  ()
 * License:
 **************************************************************/

#ifndef WX30MAIN_H
#define WX30MAIN_H

#ifndef WX_PRECOMP
    #include <wx/wx.h>
#endif

#include "wx30App.h"

class wx30Frame: public wxFrame
{
    public:
        wx30Frame(wxFrame *frame, const wxString& title);
        ~wx30Frame();
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


#endif // WX30MAIN_H
