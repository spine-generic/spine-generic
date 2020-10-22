import base64
import io
import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.graph_objs as go
import plotly.express as px
import pandas as pd
import pathlib

from scipy import stats

app = dash.Dash(__name__)
server = app.server

app.layout = html.Div(
    children=[
        #Top Banner
        html.Div(
            className="spine-generic-banner",
            children=[
                html.H2(className="h2-title", children="Spine-generic app"),
                html.Div(
                    className="div-logo",
                    children=html.Img(
                        className="logo", src=app.get_asset_url('logo.png')
                    ),
                ),
                html.H2(className="h2-title-mobile", children="Spine-generic app"),
            ],
        ),
        # Body of the app
        html.Div(
            className="row app-body",
            children=[
                # User controls
                html.Div(
                    className="four columns card",
                    children=[
                        html.Div(
                            className="bg-white",
                            children=[
                                html.Div(
                                    className="padding-top-bot",
                                    children=[
                                        html.H6("Choose type of results"),
                                        dcc.Dropdown(
                                            id='results-dropdown',
                                            options=[
                                                {'label': 'T1', 'value': 'T1'},
                                                {'label': 'Gray Matter CSA', 'value': 'Gray Matter CSA'},
                                                {'label': 'Cord CSA from T1', 'value': 'Cord CSA from T1'},
                                                {'label': 'Cord CSA from T2', 'value': 'Cord CSA from T2'},
                                                {'label': 'Fractional anisotropy', 'value': 'ractional anisotropy'},
                                                {'label': 'Mean diffusivity', 'value': 'Mean diffusivity'},
                                                {'label': 'Radial diffusivity', 'value': 'Radial diffusivity'},
                                                {'label': 'Magnetization transfer ratio', 'value': 'Magnetization transfer ratio'},
                                                {'label': 'Magnetization transfer saturation', 'value': 'Magnetization transfer saturation'}
                                                
                                            ],
                                            value='T1'
                                        )
                                    ],
                                ),
                                html.Div(
                                    className="padding-top-bot",
                                    children=[
                                        html.H6("Choose type of vendor"),
                                        dcc.Dropdown(
                                            id='fabricant-dropdown',
                                            options=[
                                                {'label': 'philips', 'value': 'philips'},
                                                {'label': 'GE', 'value': 'GE'},
                                                {'label': 'Siemens', 'value': 'Siemens'}
                                            ],
                                            value='philips'
                                        )
                                    ],
                                ),
                            ],
                        ),
                    ],
                ),
                #graph
                html.Div(
                    className="eight columns card-right",
                    children=[
                        html.Div(
                            className="bg-white",
                            children=[
                            html.H6("Graph")
                        ]
                    )
                ]
            )

        ],
    ),
        
])

if __name__ == '__main__':
    app.run_server(debug=True)


