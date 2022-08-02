%   AUTHORS:
%   Rene Labounek (1), Julien Cohen-Adad (2), Christophe Lenglet (3), Igor Nestrasil (1,3)
%   email: rlaboune@umn.edu
%
%   INSTITUTIONS:
%   (1) Masonic Institute for the Developing Brain, Division of Clinical Behavioral Neuroscience, Deparmtnet of Pediatrics, University of Minnesota, Minneapolis, Minnesota, USA
%   (2) NeuroPoly Lab, Institute of Biomedical Engineering, Polytechnique Montreal, Montreal, Quebec, Canada
%   (3) Center for Magnetic Resonance Research, Department of Radiology, University of Minnesota, Minneapolis, Minnesota, USA

xdata=[1.5 2.5];
ydata=[3.5 3.5];
plot(xdata,ydata-1,'g','LineWidth',5)
hold on
plot(xdata,ydata-2,'b','LineWidth',5)
plot(xdata,ydata-3,'r','LineWidth',5)
plot(xdata,ydata,'ko','LineStyle','none','LineWidth',3,'MarkerSize',11)
plot(xdata,ydata+1,'kx','LineStyle','none','LineWidth',3,'MarkerSize',11)
hold off
legend('Siemens','Philips','GE','female','male')
set(gca,'LineWidth',2,'FontSize',18)